# frozen_string_literal: true

class RemoveSingleTrackFieldsFromVenues < ActiveRecord::Migration[7.0]
  def up
    # Migrate any remaining track data not yet in des_venue_tracks
    execute(<<~SQL)
      INSERT INTO des_venue_tracks (venue_id, name, surface, environment, sort_order, created_at, updated_at)
      SELECT v.id, 'Main Track', v.track_surface, v.track_environment, 0, NOW(), NOW()
      FROM des_venues v
      WHERE (v.track_surface IS NOT NULL AND v.track_surface != '')
         OR (v.track_environment IS NOT NULL AND v.track_environment != '')
        AND NOT EXISTS (
          SELECT 1 FROM des_venue_tracks t WHERE t.venue_id = v.id
        )
    SQL

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
