# frozen_string_literal: true

class DesEventType < ActiveRecord::Base
  has_many :des_events

  validates :name, presence: true, uniqueness: true

  # Set per type (the produces_results column); practice sessions don't publish results.
  def produces_results?
    produces_results
  end
end
