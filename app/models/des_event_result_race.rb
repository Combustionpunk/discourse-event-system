class DesEventResultRace < ActiveRecord::Base
  belongs_to :event_result, class_name: 'DesEventResult', foreign_key: 'event_result_id'
  has_many :entries, class_name: 'DesEventResultEntry', foreign_key: 'race_id', dependent: :destroy
end
