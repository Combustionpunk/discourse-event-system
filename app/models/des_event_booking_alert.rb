# frozen_string_literal: true

class DesEventBookingAlert < ActiveRecord::Base
  belongs_to :user
  belongs_to :des_event, foreign_key: :event_id

  validates :user_id, presence: true
  validates :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event_id }
end
