# frozen_string_literal: true
class DesRacingFamilyMember < ActiveRecord::Base
  self.table_name = 'des_racing_family_members'

  # user_id = the child/dependant
  # guardian_user_id = the parent/guardian
  # family_member_user_id = legacy field (kept for backward compat, equals user_id)
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :guardian, class_name: 'User', foreign_key: 'guardian_user_id'
  belongs_to :family_member, class_name: 'User', foreign_key: 'family_member_user_id', optional: true

  validates :user_id, presence: true
  validates :guardian_user_id, presence: true

  # A guardian's dependants
  scope :for_guardian, ->(guardian_id) { where(guardian_user_id: guardian_id) }
  # A child's guardians
  scope :for_child, ->(child_id) { where(user_id: child_id) }
end
