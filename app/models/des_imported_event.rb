# frozen_string_literal: true

class DesImportedEvent < ActiveRecord::Base
  belongs_to :venue, class_name: 'DesVenue', optional: true
  belongs_to :organisation, class_name: 'DesOrganisation', optional: true

  scope :upcoming, -> { where('starts_at >= ?', Time.now) }
  scope :by_scale, ->(scale) { where(scale: scale) }
  scope :by_power, ->(power) { where(power_type: power) }
  scope :by_surface, ->(surface) { where(surface: surface) }

  def external_uids_array
    JSON.parse(external_uids || '[]')
  end

  def classes_raw_array
    JSON.parse(classes_raw || '[]')
  end
end
