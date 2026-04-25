class DesEventResult < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'
  has_many :races, class_name: 'DesEventResultRace', foreign_key: 'event_result_id', dependent: :destroy
  has_many :class_summaries, class_name: 'DesEventResultClassSummary', foreign_key: 'event_result_id', dependent: :destroy

  # statuses: pending, pending_match, confirmed, published
end
