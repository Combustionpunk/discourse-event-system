# frozen_string_literal: true

class DesVenueTrack < ActiveRecord::Base
  belongs_to :venue, class_name: 'DesVenue'

  SURFACES = %w[carpet astroturf grass tarmac dirt mixed].freeze
  ENVIRONMENTS = %w[indoor outdoor].freeze

  validates :venue_id, presence: true
  validates :surface, inclusion: { in: SURFACES }, allow_blank: true
  validates :environment, inclusion: { in: ENVIRONMENTS }, allow_blank: true

  default_scope { order(:sort_order, :id) }
end
