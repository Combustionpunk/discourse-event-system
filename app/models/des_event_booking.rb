class DesEventBooking < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :booked_by, class_name: 'User', foreign_key: 'booked_by_user_id', optional: true
  has_many :booking_classes, class_name: 'DesEventBookingClass', foreign_key: 'booking_id'
  has_many :payments, class_name: 'DesEventBookingPayment', foreign_key: 'booking_id'
  has_many :refunds, class_name: 'DesEventBookingRefund', foreign_key: 'booking_id'
  has_many :event_classes, through: :booking_classes

  validates :event_id, presence: true
  validates :user_id, presence: true
  validates :status, inclusion: { in: %w[pending confirmed cancelled refunded] }
  validate :brca_number_required_after_three_bookings

  scope :pending, -> { where(status: 'pending') }
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :refunded, -> { where(status: 'refunded') }

  before_validation :assign_brca_number, on: :create

  def confirm!
    update!(status: 'confirmed')
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def total_classes
    booking_classes.count
  end

  def previous_bookings_count
    DesEventBooking
      .where(user_id: user_id)
      .where.not(id: id)
      .where(status: %w[confirmed refunded])
      .count
  end

  def brca_required?
    previous_bookings_count >= 3
  end

  def calculate_total
    pricing_rule = event.des_event_pricing_rule
    return 0 unless pricing_rule.present?

    base_amount = pricing_rule.calculate_price(total_classes)

    # For family bookings, check the parent's membership instead of the child's
    membership_user_id = booked_by_user_id || user_id
    is_member = DesOrganisationMembership
      .where(user_id: membership_user_id, organisation_id: event.organisation_id)
      .active.exists?

    dob_str = user.custom_fields['des_date_of_birth'].presence
    dob = dob_str ? Date.parse(dob_str) : user.date_of_birth
    is_junior = if dob.present?
      age = event.start_date.year - dob.year
      age -= 1 if event.start_date < dob + age.years
      age < 16
    else
      false
    end

    discounted_amount = pricing_rule.calculate_discounted_price(total_classes, is_member, is_junior)
    discount_amount = base_amount - discounted_amount

    update!(
      total_amount: base_amount,
      discount_amount: discount_amount,
      amount_paid: discounted_amount
    )
    discounted_amount
  end

  def refundable?
    return false unless status == 'confirmed'
    event.refunds_allowed?
  end

  private

  def assign_brca_number
    brca = user.custom_fields['brca_membership_number']
    self.brca_membership_number = brca if brca.present?
  end

  def brca_number_required_after_three_bookings
    if brca_required? && brca_membership_number.blank?
      errors.add(:brca_membership_number, 'is required after your first 3 bookings. Please update your profile.')
    end
  end
end
