# frozen_string_literal: true

class DesOrganisation < ActiveRecord::Base
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  has_many :des_organisation_members, foreign_key: 'organisation_id'
  has_many :des_organisation_membership_types, foreign_key: 'organisation_id'
  has_many :des_organisation_memberships, foreign_key: 'organisation_id'
  belongs_to :discourse_group, class_name: 'Group', foreign_key: 'discourse_group_id', optional: true
  has_many :users, through: :des_organisation_members

  validates :name, presence: true, uniqueness: true
  validates :created_by, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }

  def approve!(surcharge_percentage)
    update!(status: 'approved', surcharge_percentage: surcharge_percentage)
  end

  def reject!(reason)
    update!(status: 'rejected', rejection_reason: reason)
  end
end
