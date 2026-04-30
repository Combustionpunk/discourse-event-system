# frozen_string_literal: true

module Jobs
  class DiscourseEventSystemGeocodeVenue < ::Jobs::Base
    def execute(args)
      venue = DesVenue.find_by(id: args[:venue_id])
      return unless venue
      return if venue.latitude.present? && venue.longitude.present?
      return if venue.postcode.blank?

      coords = geocode_postcode(venue.postcode)
      return unless coords

      venue.update_columns(
        latitude: coords[:lat],
        longitude: coords[:lng]
      )
    end

    private

    def geocode_postcode(postcode)
      require 'net/http'
      clean = postcode.to_s.strip.gsub(/\s+/, '').upcase
      response = Net::HTTP.get(URI("https://api.postcodes.io/postcodes/#{clean}"))
      data = JSON.parse(response)
      return nil unless data['status'] == 200
      { lat: data['result']['latitude'], lng: data['result']['longitude'] }
    rescue
      nil
    end
  end
end
