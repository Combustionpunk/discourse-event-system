# frozen_string_literal: true

class AddTrackShopAndVenueTracksUi < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:des_venues, :has_track_shop)
      add_column :des_venues, :has_track_shop, :boolean, default: false
    end
  end

  def down
    remove_column :des_venues, :has_track_shop if column_exists?(:des_venues, :has_track_shop)
  end
end
