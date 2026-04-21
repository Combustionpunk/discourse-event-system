# frozen_string_literal: true
class DesRacingFamilyMember < ActiveRecord::Base
  self.table_name = 'des_racing_family_members'

  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :family_member, class_name: 'User', foreign_key: 'family_member_user_id'

  validates :user_id, presence: true
  validates :family_member_user_id, presence: true
  validates :family_member_user_id, uniqueness: { scope: :user_id }
end
