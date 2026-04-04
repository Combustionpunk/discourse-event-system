class CreateOrganisationMembershipTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :des_organisation_membership_types do |t|
      t.integer :organisation_id, null: false
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :duration_months, null: false, default: 12
      t.decimal :discount_percentage, precision: 5, scale: 2, default: 0.0
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :des_organisation_membership_types, :organisation_id
  end
end
