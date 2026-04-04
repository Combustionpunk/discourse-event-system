class CreateOrganisations < ActiveRecord::Migration[7.0]
  def change
    create_table :des_organisations do |t|
      t.string :name, null: false
      t.text :description
      t.string :email
      t.string :phone
      t.string :website
      t.text :address
      t.string :logo_url
      t.string :google_maps_url
      t.string :paypal_email
      t.decimal :surcharge_percentage, precision: 5, scale: 2, default: 0.0
      t.integer :created_by, null: false
      t.string :status, default: 'pending'
      t.datetime :cancelled_at
      t.text :rejection_reason
      t.timestamps
    end

    add_index :des_organisations, :status
    add_index :des_organisations, :created_by
  end
end
