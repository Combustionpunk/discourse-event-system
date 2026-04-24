class AddOrgFields < ActiveRecord::Migration[7.0]
  def change
    add_column :des_organisations, :brca_affiliation_number, :string
    add_column :des_organisations, :rc_results_venue_id, :integer
  end
end
