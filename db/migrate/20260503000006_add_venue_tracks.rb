# frozen_string_literal: true

class AddVenueTracks < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:des_venue_tracks)
      create_table :des_venue_tracks do |t|
        t.integer :venue_id, null: false
        t.string :name           # e.g. "Astro", "GT", "Main Track"
        t.string :surface        # carpet, astroturf, grass, tarmac, mixed, dirt
        t.string :environment    # indoor, outdoor
        t.text :description      # optional notes about the track
        t.integer :sort_order, default: 0
        t.timestamps
      end
      add_index :des_venue_tracks, :venue_id
    end

    # Migrate existing track data from des_venues into des_venue_tracks
    # For any venue that has track_surface or track_environment set, create a track record
    execute(<<~SQL)
      INSERT INTO des_venue_tracks (venue_id, name, surface, environment, sort_order, created_at, updated_at)
      SELECT id, 'Main Track', track_surface, track_environment, 0, NOW(), NOW()
      FROM des_venues
      WHERE (track_surface IS NOT NULL AND track_surface != '')
         OR (track_environment IS NOT NULL AND track_environment != '')
    SQL
  end

  def down
    drop_table :des_venue_tracks if table_exists?(:des_venue_tracks)
  end
end
