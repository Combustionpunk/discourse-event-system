class DesEventDiscountCondition < ActiveRecord::Base
  belongs_to :discount, class_name: 'DesEventDiscount', foreign_key: 'discount_id'

  validates :discount_id, presence: true
  validates :condition_type, inclusion: { in: %w[expiry_date min_classes max_age min_age membership] }
  validates :condition_value, presence: true

  def met_by?(user, number_of_classes, event)
    case condition_type
    when 'expiry_date'
      Time.now < Time.parse(condition_value)
    when 'min_classes'
      number_of_classes >= condition_value.to_i
    when 'max_age'
      age = calculate_age(user, event.start_date)
      age.present? && age <= condition_value.to_i
    when 'min_age'
      age = calculate_age(user, event.start_date)
      age.present? && age >= condition_value.to_i
    when 'membership'
      user_is_member?(user, event)
    end
  end

  private

  def calculate_age(user, reference_date)
    return nil unless user.date_of_birth.present?
    dob = user.date_of_birth
    age = reference_date.year - dob.year
    age -= 1 if reference_date < dob + age.years
    age
  end

  def user_is_member?(user, event)
    DesOrganisationMembership
      .where(user_id: user.id, organisation_id: event.organisation_id)
      .active
      .exists?
  end
end
