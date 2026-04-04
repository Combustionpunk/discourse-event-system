# frozen_string_literal: true

class DesClassCompatibilityRule < ActiveRecord::Base
  belongs_to :class_type, class_name: 'DesEventClassType', foreign_key: 'class_type_id'

  validates :class_type_id, presence: true
  validates :rule_type, inclusion: { in: %w[driveline max_year min_year manufacturer model chassis] }
  validates :rule_value, presence: true

  def car_eligible?(car)
    case rule_type
    when 'driveline'
      allowed = rule_value.split(',').map(&:strip)
      allowed.include?(car.effective_driveline)
    when 'chassis'
      allowed = rule_value.split(',').map(&:strip)
      allowed.include?(car.car_model&.chassis_type)
    when 'max_year'
      car.year_released.present? && car.year_released <= rule_value.to_i
    when 'min_year'
      car.year_released.present? && car.year_released >= rule_value.to_i
    when 'manufacturer'
      car.manufacturer_id == rule_value.to_i
    when 'model'
      car.car_model_id == rule_value.to_i
    end
  end
end
