# frozen_string_literal: true

class DesCarModel < ActiveRecord::Base
  belongs_to :manufacturer, class_name: 'DesManufacturer', foreign_key: 'manufacturer_id'
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  has_many :user_cars, class_name: 'DesUserCar', foreign_key: 'car_model_id'

  DRIVELINES = ['2WD', '4WD', 'FWD', 'Rear Motor'].freeze
  CHASSIS_TYPES = [
    '1/8 Buggy', '1/8 Truck',
    '1/10 Buggy', '1/10 Stadium', '1/10 Short course',
    '1/10 Touring Car', '1/10 Rally', '1/10 Pan car',
    '1/12 Pan car', '1/28 Touring car', '1/28 Buggy', '1/28 Truck'
  ].freeze

  validates :manufacturer_id, presence: true
  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validates :driveline, inclusion: { in: DRIVELINES }, allow_nil: true

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
end
