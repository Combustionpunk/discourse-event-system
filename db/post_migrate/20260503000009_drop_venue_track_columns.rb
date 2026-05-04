# frozen_string_literal: true

class DropVenueTrackColumns < ActiveRecord::Migration[7.0]
  def up
    remove_column :des_venues, :track_surface if column_exists?(:des_venues, :track_surface)
    remove_column :des_venues, :track_environment if column_exists?(:des_venues, :track_environment)
    remove_column :des_venues, :track_category if column_exists?(:des_venues, :track_category)
    remove_column :des_venues, :track_type if column_exists?(:des_venues, :track_type)
  end

  def down
    add_column :des_venues, :track_surface, :string unless column_exists?(:des_venues, :track_surface)
    add_column :des_venues, :track_environment, :string unless column_exists?(:des_venues, :track_environment)
    add_column :des_venues, :track_category, :string unless column_exists?(:des_venues, :track_category)
    add_column :des_venues, :track_type, :string unless column_exists?(:des_venues, :track_type)
  end
end
