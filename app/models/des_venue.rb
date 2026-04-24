# frozen_string_literal: true
class DesVenue < ActiveRecord::Base
  self.table_name = 'des_venues'

  TRACK_CATEGORIES = %w[onroad offroad].freeze
  TRACK_SURFACES = %w[carpet astroturf grass tarmac mixed].freeze
  TRACK_ENVIRONMENTS = %w[outdoor indoor_covered].freeze
  FACILITIES = %w[has_portaloos has_permanent_toilets has_bar has_showers has_power_supply has_water_supply has_camping].freeze

  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'created_by_organisation_id', optional: true
  has_many :events, class_name: 'DesEvent', foreign_key: 'venue_id'

  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending approved] }
  validates :track_category, inclusion: { in: TRACK_CATEGORIES, allow_blank: true }
  validates :track_surface, inclusion: { in: TRACK_SURFACES, allow_blank: true }
  validates :track_environment, inclusion: { in: TRACK_ENVIRONMENTS, allow_blank: true }

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :shared, -> { where(is_shared: true) }
  scope :exclusive, -> { where(is_shared: false) }

  def approve!
    update!(status: 'approved')
  end
end
