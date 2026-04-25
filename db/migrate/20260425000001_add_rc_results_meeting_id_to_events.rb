class AddRcResultsMeetingIdToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :des_events, :rc_results_meeting_id, :integer, null: true
  end
end
