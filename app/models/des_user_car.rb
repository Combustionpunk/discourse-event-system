# frozen_string_literal: true

class DesUserCar < ActiveRecord::Base
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :manufacturer, class_name: 'DesManufacturer', foreign_key: 'manufacturer_id'
  belongs_to :car_model, class_name: 'DesCarModel', foreign_key: 'car_model_id', optional: true
  belongs_to :class_type, class_name: 'DesEventClassType', foreign_key: 'class_type_id', optional: true

  DRIVELINES = ['2WD', '4WD', 'FWD', 'Rear Motor'].freeze

  validates :user_id, presence: true
  validates :manufacturer_id, presence: true
  validates :transponder_number, presence: true
  validates :transponder_number, format: {
    with: /\A\d{7}\z/,
    message: "must be exactly 7 digits"
  }

  scope :active, -> { where(status: 'active') }

  def display_name
    friendly_name.presence || "#{manufacturer.name} #{model_name} (#{effective_driveline})"
  end

  def model_name
    car_model&.name || custom_model_name || 'Unknown Model'
  end

  def year_released
    car_model&.year_released
  end

  def effective_driveline
    car_model&.driveline || driveline
  end

  def model_approved?
    car_model.present? && car_model.status == 'approved'
  end

  def eligible_for_class?(event_class)
    class_type_id = event_class.respond_to?(:class_type_id) ? event_class.class_type_id : event_class.id
    rules = DesClassCompatibilityRule.where(class_type_id: class_type_id)
    return true if rules.empty?
    rules.all? { |rule| rule.car_eligible?(self) }
  end
end
