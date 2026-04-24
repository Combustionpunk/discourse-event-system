# frozen_string_literal: true

class DesEvent < ActiveRecord::Base
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'
  belongs_to :event_type, class_name: 'DesEventType', foreign_key: 'event_type_id'
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by'
  belongs_to :topic, class_name: 'Topic', foreign_key: 'topic_id', optional: true
  belongs_to :venue, class_name: 'DesVenue', foreign_key: 'venue_id', optional: true
  belongs_to :category, class_name: 'Category', foreign_key: 'category_id', optional: true

  has_many :des_event_classes, foreign_key: 'event_id'
  has_many :des_event_bookings, foreign_key: 'event_id'
  has_one :des_event_pricing_rule, foreign_key: 'event_id'
  has_many :des_event_discounts, foreign_key: 'event_id'

  validates :title, presence: true
  validates :organisation_id, presence: true
  validate :end_date_after_start_date

  def end_date_after_start_date
    return unless start_date.present? && end_date.present?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
  validates :event_type_id, presence: true
  validates :created_by, presence: true
  validates :start_date, presence: true
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true
  validates :status, inclusion: { in: %w[draft published sold_out cancelled completed] }

  scope :published, -> { where(status: 'published') }
  scope :draft, -> { where(status: 'draft') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :completed, -> { where(status: 'completed') }
  scope :upcoming, -> { where(status: 'published').where('start_date > ?', Time.now) }
  scope :past, -> { where(status: 'completed').where('start_date < ?', Time.now) }

  def publish!
    create_topic! unless topic_id.present?
    update!(status: 'published')
  end

  def cancel!(reason)
    update!(status: 'cancelled', cancelled_at: Time.now, cancellation_reason: reason)
    update_topic_title!("CANCELLED - #{title}") if topic_id.present?
  end

  def complete!
    update!(status: 'completed')
  end

  def sold_out?
    status == 'sold_out'
  end

  def refunds_allowed?
    return false if status == 'cancelled'
    return false if start_date < Time.now
    (start_date - Time.now) / 1.day >= refund_cutoff_days
  end

  def total_bookings
    des_event_classes.sum(:capacity)
  end

  def create_topic!
    creator_user = User.find(created_by)
    category_slug = SiteSetting.discourse_event_system_category_slug.presence || 'rc-meetings'
    events_category_id = Category.find_by(slug: category_slug)&.id || SiteSetting.uncategorized_category_id
    topic_tags = build_topic_tags

    post_creator = PostCreator.new(
      creator_user,
      title: title,
      raw: build_post_content,
      category: events_category_id,
      tags: topic_tags,
      skip_validations: true,
      skip_jobs: false
    )

    post = post_creator.create
    raise "Failed to create topic: #{post_creator.errors.full_messages.join(', ')}" unless post&.persisted?

    update!(topic_id: post.topic_id, category_id: events_category_id)
    post.topic
  end

  def build_topic_tags
    tags = []
    if organisation.present?
      org_tag = organisation.name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
      tags << org_tag
    end
    if event_type.present?
      type_tag = event_type.name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
      tags << type_tag
    end
    des_event_classes.each do |ec|
      class_tag = ec.name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
      tags << class_tag
    end
    tags.uniq.each { |tag_name| Tag.find_or_create_by!(name: tag_name) }
    tags.uniq
  end

  def update_topic_content!
    return unless topic_id.present?
    creator_user = User.find(created_by)
    post = topic.first_post
    post.revise(creator_user, { raw: build_post_content }, skip_validations: true)
  end


  def cancel_topic_content!(reason = nil)
    return unless topic_id.present?
    creator_user = User.find(created_by)

    # Prepend [CANCELLED] to topic title
    unless topic.title.start_with?("[CANCELLED]")
      topic.update!(title: "[CANCELLED] #{topic.title}")
    end

    # Post cancellation announcement
    message = "⚠️ **This event has been cancelled.**"
    message += "\n\n#{reason}" if reason.present?
    message += "\n\nAll bookings have been cancelled and refunds have been processed."

    PostCreator.new(
      creator_user,
      topic_id: topic_id,
      raw: message,
      skip_validations: true
    ).create
  rescue => e
    Rails.logger.error "Failed to update topic for cancelled event #{id}: #{e.message}"
  end

  private

  def update_topic_title!(new_title)
    return unless topic_id.present?
    topic.update!(title: new_title)
  end

  def build_post_content
    if description.present?
      description
    else
      "Event details are shown in the booking widget above."
    end
  end
end
