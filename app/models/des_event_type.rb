# frozen_string_literal: true

class DesEventType < ActiveRecord::Base
  has_many :des_events

  validates :name, presence: true, uniqueness: true

  # Championship rounds are the meetings whose results get imported and published.
  def produces_results?
    name.to_s.match?(/championship/i)
  end
end
