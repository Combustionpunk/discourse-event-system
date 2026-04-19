# frozen_string_literal: true
class DesOrganisationMembership < ActiveRecord::Base
  self.table_name = 'des_organisation_memberships'

  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :membership_type, class_name: 'DesOrganisationMembershipType', foreign_key: 'membership_type_id'
  has_many :family_members, class_name: 'DesMembershipFamilyMember', foreign_key: 'membership_id'
  has_many :family_users, through: :family_members, source: :user

  validates :organisation_id, presence: true
  validates :user_id, presence: true
  validates :membership_type_id, presence: true
  validates :status, inclusion: { in: %w[pending active expired cancelled] }

  scope :active, -> { where(status: 'active').where('expires_at > ?', Time.now) }
  scope :expired, -> { where(status: 'active').where('expires_at <= ?', Time.now) }
  scope :pending, -> { where(status: 'pending') }

  def activate!(capture_id, amount)
    update!(
      status: 'active',
      paypal_capture_id: capture_id,
      amount_paid: amount,
      starts_at: Time.now,
      expires_at: Time.now + membership_type.duration_months.months
    )
    # Add primary user and family members to Discourse group
    add_to_discourse_group!
    family_users.each { |u| add_user_to_discourse_group!(u) }
  end

  def add_family_member!(new_user)
    raise "Membership is not active" unless status == 'active'
    raise "Family membership full" if family_members.count >= membership_type.max_members - 1
    family_members.create!(user_id: new_user.id)
    add_user_to_discourse_group!(new_user)
  end

  def remove_family_member!(member_user)
    fm = family_members.find_by(user_id: member_user.id)
    return unless fm
    fm.destroy
    remove_user_from_discourse_group!(member_user)
  end

  def expire!
    update!(status: 'expired')
    remove_from_discourse_group!
  end

  def cancel!
    update!(status: 'cancelled')
    remove_from_discourse_group!
  end

  private

  def add_to_discourse_group!
    group_id = organisation.discourse_group_id
    return unless group_id
    group = Group.find_by(id: group_id)
    return unless group
    group.add(user) unless group.users.include?(user)
  rescue => e
    Rails.logger.error "Failed to add user to group: #{e.message}"
  end

  def add_user_to_discourse_group!(target_user)
    group_id = organisation.discourse_group_id
    return unless group_id
    group = Group.find_by(id: group_id)
    return unless group
    group.add(target_user) unless group.users.include?(target_user)
  rescue => e
    Rails.logger.error "Failed to add user to group: #{e.message}"
  end

  def remove_user_from_discourse_group!(target_user)
    group_id = organisation.discourse_group_id
    return unless group_id
    group = Group.find_by(id: group_id)
    return unless group
    group.remove(target_user)
  rescue => e
    Rails.logger.error "Failed to remove user from group: #{e.message}"
  end

  def remove_from_discourse_group!
    group_id = organisation.discourse_group_id
    return unless group_id
    group = Group.find_by(id: group_id)
    return unless group
    # Only remove if no other active memberships
    other_active = DesOrganisationMembership
      .where(organisation_id: organisation_id, user_id: user_id, status: 'active')
      .where.not(id: id)
      .where('expires_at > ?', Time.now)
      .exists?
    group.remove(user) unless other_active
  rescue => e
    Rails.logger.error "Failed to remove user from group: #{e.message}"
  end
end
