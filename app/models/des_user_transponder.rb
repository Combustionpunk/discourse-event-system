# frozen_string_literal: true

class DesUserTransponder < ActiveRecord::Base
  belongs_to :user
  has_many :user_cars, class_name: 'DesUserCar', foreign_key: 'transponder_number', primary_key: 'long_code'

  validates :user_id, presence: true
  validates :shortcode, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :long_code, presence: true
  validates :shortcode, uniqueness: { scope: :user_id }
  validates :long_code, uniqueness: { scope: :user_id }

  scope :for_user, ->(user_id) { where(user_id: user_id).order(:shortcode) }

  def display_name
    "##{shortcode} - #{long_code}#{notes.present? ? " (#{notes})" : ""}"
  end

  def self.next_shortcode_for(user_id)
    maximum_shortcode = for_user(user_id).maximum(:shortcode) || 0
    maximum_shortcode + 1
  end
end
