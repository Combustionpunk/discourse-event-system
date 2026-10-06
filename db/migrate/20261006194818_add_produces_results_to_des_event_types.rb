# frozen_string_literal: true
class AddProducesResultsToDesEventTypes < ActiveRecord::Migration[8.1]
  def change
    # Race meetings of every kind publish results; practice sessions are the exception.
    add_column :des_event_types, :produces_results, :boolean, null: false, default: true

    up_only { execute <<~SQL }
      UPDATE des_event_types SET produces_results = false WHERE LOWER(name) = 'practice'
    SQL
  end
end
