class AddOrganisationIdToEventClassTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_class_types, :organisation_id, :integer, null: true
    add_index :des_event_class_types, :organisation_id
  end
end
