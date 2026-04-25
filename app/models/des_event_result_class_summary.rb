class DesEventResultClassSummary < ActiveRecord::Base
  belongs_to :event_result, class_name: 'DesEventResult', foreign_key: 'event_result_id'
  belongs_to :first_user, class_name: 'User', foreign_key: 'first_user_id', optional: true
  belongs_to :second_user, class_name: 'User', foreign_key: 'second_user_id', optional: true
  belongs_to :third_user, class_name: 'User', foreign_key: 'third_user_id', optional: true
  belongs_to :fastest_lap_user, class_name: 'User', foreign_key: 'fastest_lap_user_id', optional: true
end
