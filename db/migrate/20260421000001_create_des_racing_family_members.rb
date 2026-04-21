class CreateDesRacingFamilyMembers < ActiveRecord::Migration[7.0]
  def change
    create_table :des_racing_family_members do |t|
      t.integer :user_id, null: false
      t.integer :family_member_user_id, null: false
      t.timestamps
    end

    add_index :des_racing_family_members, :user_id
    add_index :des_racing_family_members, [:user_id, :family_member_user_id], unique: true, name: 'idx_racing_family_unique'
  end
end
