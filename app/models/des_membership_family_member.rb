# frozen_string_literal: true
class DesMembershipFamilyMember < ActiveRecord::Base
  self.table_name = 'des_membership_family_members'

  belongs_to :membership, class_name: 'DesOrganisationMembership', foreign_key: 'membership_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'

  validates :membership_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :membership_id }
end
