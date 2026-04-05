class AddOrganisationIdToClassCompatibilityRules < ActiveRecord::Migration[7.0]
  def change
    add_column :des_class_compatibility_rules, :organisation_id, :integer, null: true
    add_index :des_class_compatibility_rules, :organisation_id
  end
end
