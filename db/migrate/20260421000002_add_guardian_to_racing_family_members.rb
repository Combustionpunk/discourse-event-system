class AddGuardianToRacingFamilyMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :des_racing_family_members, :guardian_user_id, :integer
    add_column :des_racing_family_members, :created_by_guardian, :boolean, default: false
    add_index :des_racing_family_members, :guardian_user_id

    # Migrate existing data: treat user_id as guardian, family_member_user_id as child
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE des_racing_family_members
          SET guardian_user_id = user_id
          WHERE guardian_user_id IS NULL
        SQL
      end
    end
  end
end
