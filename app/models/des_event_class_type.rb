# frozen_string_literal: true
class DesEventClassType < ActiveRecord::Base
  self.table_name = 'des_event_class_types'

  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id', optional: true
  has_many :des_event_classes
  has_many :compatibility_rules, class_name: 'DesClassCompatibilityRule', foreign_key: 'class_type_id'

  scope :global, -> { where(organisation_id: nil) }
  scope :for_organisation, ->(org_id) { where(organisation_id: org_id) }
  scope :available_for, ->(org_id) { where(organisation_id: [nil, org_id]) }

  validates :name, presence: true
  validates :name, uniqueness: { scope: :organisation_id }
  validates :track_environment, inclusion: { in: %w[onroad offroad] }, allow_nil: true

  def chassis_types_list
    chassis_types.present? ? chassis_types.split(',').map(&:strip) : []
  end

  def drivelines_list
    drivelines.present? ? drivelines.split(',').map(&:strip) : []
  end

  def car_eligible?(car)
    return false if scale.present? && car.car_model&.scale != scale
    return false if chassis_types_list.any? && !chassis_types_list.include?(car.car_model&.chassis_type)
    return false if drivelines_list.any? && !drivelines_list.include?(car.effective_driveline)
    return false if min_year.present? && (car.year_released.blank? || car.year_released < min_year)
    return false if max_year.present? && (car.year_released.blank? || car.year_released > max_year)
    return false if manufacturer.present? && car.manufacturer&.name != manufacturer
    return false if model_id.present? && car.car_model_id != model_id
    true
  end

  def driver_eligible?(user)
    return true if min_age.blank? && max_age.blank?
    dob_str = UserCustomField.find_by(user_id: user.id, name: 'des_date_of_birth')&.value.presence
    return true unless dob_str
    age = ((Time.now - Date.parse(dob_str).to_time) / 1.year.seconds).floor
    return false if min_age.present? && age < min_age
    return false if max_age.present? && age > max_age
    true
  end
end
