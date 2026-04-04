class DesEventWaitlist < ActiveRecord::Base
  self.table_name = 'des_event_waitlist'

  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'
  belongs_to :event_class, class_name: 'DesEventClass', foreign_key: 'event_class_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'

  validates :event_id, presence: true
  validates :event_class_id, presence: true
  validates :user_id, presence: true
  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[waiting notified converted expired] }

  scope :waiting, -> { where(status: 'waiting').order(:position) }
  scope :notified, -> { where(status: 'notified') }
  scope :converted, -> { where(status: 'converted') }

  def self.add_to_waitlist(event, event_class, user)
    next_position = where(event_class_id: event_class.id).maximum(:position).to_i + 1
    create!(
      event_id: event.id,
      event_class_id: event_class.id,
      user_id: user.id,
      position: next_position,
      status: 'waiting'
    )
  end

  def notify!
    update!(status: 'notified')
  end

  def convert!
    update!(status: 'converted')
    reorder_waitlist!
  end

  def expire!
    update!(status: 'expired')
    reorder_waitlist!
  end

  private

  def reorder_waitlist!
    remaining = DesEventWaitlist
      .where(event_class_id: event_class_id, status: 'waiting')
      .order(:position)
    remaining.each_with_index do |entry, index|
      entry.update!(position: index + 1)
    end
  end
end
