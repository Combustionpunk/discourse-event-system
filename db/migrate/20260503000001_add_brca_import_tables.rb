# frozen_string_literal: true

class AddBrcaImportTables < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:des_imported_events)
      create_table :des_imported_events do |t|
        t.string   :source,            null: false, default: 'brca'
        t.text     :external_uids      # JSON array of BRCA UIDs grouped into this event
        t.string   :title,             null: false
        t.string   :discipline         # '10th Off Road', '8th Circuit' etc
        t.string   :series_type        # 'national', 'regional', 'clubman', 'affiliated'
        t.string   :region             # 'North West', 'East Mids' etc, nullable
        t.integer  :round_number       # nullable
        t.text     :classes_raw        # JSON array of raw class names from feed
        t.string   :scale              # '1/10', '1/8', '1/12', 'large_scale'
        t.string   :power_type         # 'electric', 'nitro', 'petrol', 'mixed'
        t.string   :surface            # 'on_road', 'off_road'
        t.datetime :starts_at,         null: false
        t.datetime :ends_at
        t.integer  :venue_id           # FK → des_venues, nullable
        t.string   :booking_url        # Link to BRCA booking page, nullable
        t.timestamps
      end
    end

    unless index_exists?(:des_imported_events, :source)
      add_index :des_imported_events, :source
    end

    unless index_exists?(:des_imported_events, :external_uids, unique: true)
      add_index :des_imported_events, :external_uids, unique: true
    end

    unless table_exists?(:des_venue_suggestions)
      create_table :des_venue_suggestions do |t|
        t.integer  :venue_id,          null: false
        t.integer  :user_id,           null: false
        t.jsonb    :suggested_data,    null: false, default: {}
        t.string   :status,            null: false, default: 'pending'
        # status values: pending, approved, rejected
        t.text     :admin_notes
        t.timestamps
      end
    end

    unless index_exists?(:des_venue_suggestions, [:venue_id, :user_id, :status])
      add_index :des_venue_suggestions, [:venue_id, :user_id, :status]
    end
  end

  def down
    drop_table :des_venue_suggestions if table_exists?(:des_venue_suggestions)
    drop_table :des_imported_events if table_exists?(:des_imported_events)
  end
end
