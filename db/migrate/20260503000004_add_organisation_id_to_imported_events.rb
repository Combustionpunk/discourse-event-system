# frozen_string_literal: true

class AddOrganisationIdToImportedEvents < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:des_imported_events, :organisation_id)
      add_column :des_imported_events, :organisation_id, :integer
      add_index :des_imported_events, :organisation_id
    end

    # Ensure BRCA organisation exists
    unless DesOrganisation.exists?(name: 'BRCA')
      admin_id = User.where(admin: true).pick(:id) || 1
      DesOrganisation.create!(
        name: 'BRCA',
        status: 'approved',
        description: 'British Radio Car Association — national governing body for RC car racing in the UK',
        website: 'https://www.brca.org',
        created_by: admin_id
      )
    end

    # Link all existing imported events to BRCA org
    execute(<<~SQL)
      UPDATE des_imported_events
      SET organisation_id = (
        SELECT id FROM des_organisations WHERE name = 'BRCA' LIMIT 1
      )
      WHERE organisation_id IS NULL
    SQL
  end

  def down
    remove_column :des_imported_events, :organisation_id if column_exists?(:des_imported_events, :organisation_id)
  end
end
