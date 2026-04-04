class MakeEventCapacityNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :des_events, :capacity, true
  end
end
