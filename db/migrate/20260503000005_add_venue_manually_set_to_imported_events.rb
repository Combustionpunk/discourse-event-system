# frozen_string_literal: true

class AddVenueManuallySetToImportedEvents < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:des_imported_events, :venue_manually_set)
      add_column :des_imported_events, :venue_manually_set, :boolean, default: false
    end
  end

  def down
    remove_column :des_imported_events, :venue_manually_set if column_exists?(:des_imported_events, :venue_manually_set)
  end
end
