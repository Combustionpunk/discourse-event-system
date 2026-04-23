class DesEventBookingClass < ActiveRecord::Base
  belongs_to :booking, class_name: 'DesEventBooking', foreign_key: 'booking_id'
  belongs_to :event_class, class_name: 'DesEventClass', foreign_key: 'event_class_id'
  belongs_to :user_car, class_name: 'DesUserCar', foreign_key: 'car_id', optional: true

  validates :booking_id, presence: true
  validates :event_class_id, presence: true
  validates :status, inclusion: { in: %w[confirmed cancelled] }

  scope :confirmed, -> { where(status: 'confirmed') }
  scope :cancelled, -> { where(status: 'cancelled') }

  after_create :update_class_status
  after_update :update_class_status, if: -> { saved_change_to_status? }

  def assign_transponder(user, car_owner: nil)
    # For family bookings, use the parent's garage (car_owner) instead of the child's
    garage_user = car_owner || user
    car = DesUserCar.active
      .where(user_id: garage_user.id)
      .joins(:car_model)
      .first
    if car.present? && car.transponder_number.present?
      update!(transponder_number: car.transponder_number)
    end
  end

  def override_transponder!(number)
    update!(
      transponder_number: number,
      transponder_overridden: true
    )
  end

  private

  def update_class_status
    event_class.update_status!
  end
end
