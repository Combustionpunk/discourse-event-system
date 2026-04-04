class CreateDiscourseEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :des_events do |t|
      t.integer :organisation_id, null: false
      t.integer :event_type_id, null: false
      t.integer :created_by, null: false
      t.string :title, null: false
      t.text :description
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.string :location
      t.string :google_maps_url
      t.decimal :price, precision: 10, scale: 2, default: 0.0
      t.integer :capacity, null: false
      t.string :status, default: 'draft'
      t.integer :refund_cutoff_days, default: 7
      t.datetime :cancelled_at
      t.text :cancellation_reason
      t.timestamps
    end

    add_index :des_events, :organisation_id
    add_index :des_events, :event_type_id
    add_index :des_events, :status
    add_index :des_events, :start_date
  end
end
