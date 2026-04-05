# frozen_string_literal: true
class DesEventClassType < ActiveRecord::Base
  self.table_name = 'des_event_class_types'

  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id', optional: true
  has_many :des_event_classes
  has_many :compatibility_rules, class_name: 'DesClassCompatibilityRule', foreign_key: 'class_type_id'

  scope :global, -> { where(organisation_id: nil) }
  scope :for_organisation, ->(org_id) { where(organisation_id: org_id) }
  scope :available_for, ->(org_id) { where(organisation_id: [nil, org_id]) }

  validates :name, presence: true
  validates :name, uniqueness: { scope: :organisation_id }
end
