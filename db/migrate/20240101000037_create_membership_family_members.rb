class CreateMembershipFamilyMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :des_organisation_membership_types, :max_members, :integer, default: 1, null: false
    add_column :des_organisation_membership_types, :is_family, :boolean, default: false, null: false

    create_table :des_membership_family_members do |t|
      t.integer :membership_id, null: false
      t.integer :user_id, null: false
      t.timestamps
    end

    add_index :des_membership_family_members, :membership_id
    add_index :des_membership_family_members, [:membership_id, :user_id],
              unique: true, name: 'idx_membership_family_members_unique'
  end
end
