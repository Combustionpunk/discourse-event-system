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
    # Columns dropped in post-migration 20260503000009
  end

  def down; end
end
