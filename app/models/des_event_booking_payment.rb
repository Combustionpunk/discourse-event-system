class DesEventBookingPayment < ActiveRecord::Base
  belongs_to :booking, class_name: 'DesEventBooking', foreign_key: 'booking_id'
  has_many :refunds, class_name: 'DesEventBookingRefund', foreign_key: 'payment_id'

  validates :booking_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_type, inclusion: { in: %w[initial additional] }
  validates :status, inclusion: { in: %w[pending completed failed refunded] }

  scope :completed, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :initial, -> { where(payment_type: 'initial') }
  scope :additional, -> { where(payment_type: 'additional') }

  def complete!(paypal_capture_id)
    update!(
      status: 'completed',
      paypal_capture_id: paypal_capture_id
    )
    booking.confirm!
  end

  def fail!
    update!(status: 'failed')
  end

  def total_refunded
    refunds.where(status: 'completed').sum(:amount)
  end

  def refundable_amount
    amount - total_refunded
  end
end
