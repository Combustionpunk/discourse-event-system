class CreateDesVenues < ActiveRecord::Migration[7.0]
  def change
    create_table :des_venues do |t|
      t.string :name, null: false
      t.string :address
      t.string :google_maps_url
      t.string :track_category
      t.string :track_surface
      t.string :track_environment
      t.string :website
      t.text :description
      t.text :parking_info
      t.text :local_facilities
      t.text :access_notes
      t.string :status, default: 'pending'
      t.integer :created_by_organisation_id
      t.boolean :has_portaloos, default: false
      t.boolean :has_permanent_toilets, default: false
      t.boolean :has_bar, default: false
      t.boolean :has_showers, default: false
      t.boolean :has_power_supply, default: false
      t.boolean :has_water_supply, default: false
      t.boolean :has_camping, default: false
      t.timestamps
    end

    add_index :des_venues, :status
    add_index :des_venues, :created_by_organisation_id
  end
end
