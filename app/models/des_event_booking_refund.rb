class DesEventBookingRefund < ActiveRecord::Base
  belongs_to :booking, class_name: 'DesEventBooking', foreign_key: 'booking_id'
  belongs_to :payment, class_name: 'DesEventBookingPayment', foreign_key: 'payment_id'
  belongs_to :initiator, class_name: 'User', foreign_key: 'initiated_by'

  validates :booking_id, presence: true
  validates :payment_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :initiated_by, presence: true
  validates :status, inclusion: { in: %w[pending completed failed] }

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :event_cancellations, -> { where(event_cancellation: true) }

  def complete!(paypal_refund_id)
    update!(
      status: 'completed',
      paypal_refund_id: paypal_refund_id
    )
    check_booking_status!
  end

  def fail!
    update!(status: 'failed')
  end

  private

  def check_booking_status!
    total_paid = booking.payments.completed.sum(:amount)
    total_refunded = booking.refunds.completed.sum(:amount)
    if total_refunded >= total_paid
      booking.update!(status: 'refunded')
    end
  end
end
