# frozen_string_literal: true

class AddTrackTypeToVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :des_venues, :track_type, :string
  end
end
