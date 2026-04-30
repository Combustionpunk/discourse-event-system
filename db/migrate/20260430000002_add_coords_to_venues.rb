# frozen_string_literal: true

class AddCoordsToVenues < ActiveRecord::Migration[7.0]
  def change
    add_column :des_venues, :latitude, :decimal, precision: 10, scale: 6
    add_column :des_venues, :longitude, :decimal, precision: 10, scale: 6
  end
end
