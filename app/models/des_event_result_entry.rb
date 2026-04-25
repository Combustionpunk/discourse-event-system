class DesEventResultEntry < ActiveRecord::Base
  belongs_to :race, class_name: 'DesEventResultRace', foreign_key: 'race_id'
  belongs_to :user, optional: true
end
