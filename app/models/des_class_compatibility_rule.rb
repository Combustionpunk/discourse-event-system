# frozen_string_literal: true

class DesClassCompatibilityRule < ActiveRecord::Base
  belongs_to :class_type, class_name: 'DesEventClassType', foreign_key: 'class_type_id'
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id', optional: true

  scope :global, -> { where(organisation_id: nil) }
  scope :for_organisation, ->(org_id) { where(organisation_id: org_id) }
  scope :applicable_to, ->(org_id) { where(organisation_id: [nil, org_id]) }

  validates :class_type_id, presence: true
  validates :rule_type, inclusion: { in: %w[driveline max_year min_year manufacturer model chassis max_age min_age] }
  validates :rule_value, presence: true

  def driver_eligible?(user)
    dob = user.custom_fields['des_date_of_birth']
    return true unless dob.present?
    age = ((Time.now - Date.parse(dob).to_time) / 1.year.seconds).floor
    case rule_type
    when 'max_age'
      age <= rule_value.to_i
    when 'min_age'
      age >= rule_value.to_i
    else
      true
    end
  rescue
    true
  end

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
      allowed = rule_value.split(',').map(&:strip)
      allowed.include?(car.manufacturer&.name)
    when 'model'
      car.car_model_id == rule_value.to_i
    end
  end
end
