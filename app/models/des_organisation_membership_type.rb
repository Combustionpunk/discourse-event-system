# frozen_string_literal: true
class DesOrganisationMembershipType < ActiveRecord::Base
  self.table_name = 'des_organisation_membership_types'

  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_months, presence: true, numericality: { greater_than: 0 }
  validates :organisation_id, presence: true

  scope :active, -> { where(active: true) }

  def free?
    price.to_f == 0
  end
end
