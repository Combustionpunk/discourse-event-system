class AddLapRejectionToResultEntries < ActiveRecord::Migration[7.0]
  def change
    add_column :des_event_result_entries, :best_lap_rejected, :boolean, default: false
    add_column :des_event_result_entries, :best_lap_rejection_reason, :string
  end
end
