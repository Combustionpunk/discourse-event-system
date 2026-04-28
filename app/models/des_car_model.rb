# frozen_string_literal: true

class DesCarModel < ActiveRecord::Base
  belongs_to :manufacturer, class_name: 'DesManufacturer', foreign_key: 'manufacturer_id'
  belongs_to :creator, class_name: 'User', foreign_key: 'created_by', optional: true
  has_many :user_cars, class_name: 'DesUserCar', foreign_key: 'car_model_id'

  DRIVELINES = ['2WD', '4WD', 'FWD', 'Rear Motor'].freeze
  SCALES = ['1/8', '1/10', '1/12', '1/28'].freeze

  CHASSIS_TYPES = [
    'Buggy', 'Truck', 'Stadium', 'Short Course',
    'Touring Car', 'Rally', 'Pan Car', 'Drift'
  ].freeze

  validates :manufacturer_id, presence: true
  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validates :driveline, inclusion: { in: DRIVELINES }, allow_nil: true
  validates :scale, inclusion: { in: SCALES }, allow_nil: true

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
end
