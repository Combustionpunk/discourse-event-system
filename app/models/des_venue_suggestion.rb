# frozen_string_literal: true

class DesVenueSuggestion < ActiveRecord::Base
  belongs_to :venue, class_name: 'DesVenue'
  belongs_to :user

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
end
