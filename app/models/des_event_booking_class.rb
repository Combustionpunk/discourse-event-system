class DesEventBookingClass < ActiveRecord::Base
  belongs_to :booking, class_name: 'DesEventBooking', foreign_key: 'booking_id'
  belongs_to :event_class, class_name: 'DesEventClass', foreign_key: 'event_class_id'

  validates :booking_id, presence: true
  validates :event_class_id, presence: true
  validates :status, inclusion: { in: %w[confirmed cancelled] }

  scope :confirmed, -> { where(status: 'confirmed') }
  scope :cancelled, -> { where(status: 'cancelled') }

  after_create :update_class_status
  after_update :update_class_status

  def assign_transponder(user)
    # Find a car in the user's garage that's eligible for this class
    car = DesUserCar.active
      .where(user_id: user.id)
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
