# frozen_string_literal: true
class DesVenue < ActiveRecord::Base
  self.table_name = 'des_venues'

  FACILITIES = %w[has_portaloos has_permanent_toilets has_bar has_cafe has_showers has_power_supply has_water_supply has_camping has_track_shop].freeze

  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'created_by_organisation_id', optional: true
  belongs_to :claimed_organisation, class_name: 'DesOrganisation', optional: true
  has_many :events, class_name: 'DesEvent', foreign_key: 'venue_id'
  has_many :venue_suggestions, class_name: 'DesVenueSuggestion'
  has_many :imported_events, class_name: 'DesImportedEvent'
  has_many :tracks, class_name: 'DesVenueTrack', foreign_key: 'venue_id', dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending approved] }

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :shared, -> { where(is_shared: true) }
  scope :exclusive, -> { where(is_shared: false) }
  scope :stubs, -> { where(is_stub: true) }
  scope :claimed, -> { where(claim_status: 'approved') }
  scope :unclaimed, -> { where(claim_status: 'unclaimed') }

  after_save :geocode_if_needed

  def geocode_if_needed
    return unless saved_change_to_postcode? || (latitude.blank? && postcode.present?)
    return if postcode.blank?
    return if latitude.present? && longitude.present? && !saved_change_to_postcode?
    # Clear coords if postcode changed so they get re-geocoded
    update_columns(latitude: nil, longitude: nil) if saved_change_to_postcode? && latitude.present?
    ::Jobs.enqueue(:discourse_event_system_geocode_venue, venue_id: id)
  rescue => e
    Rails.logger.warn("Failed to enqueue geocode job for venue #{id}: #{e.message}")
  end

  def primary_track
    tracks.first
  end

  def all_surfaces
    tracks.map(&:surface).compact.uniq
  end

  def all_environments
    tracks.map(&:environment).compact.uniq
  end

  def approve!
    update!(status: 'approved')
  end
end
