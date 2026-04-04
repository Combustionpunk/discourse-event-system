class DesEventCancellationRefund < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'
  belongs_to :initiator, class_name: 'User', foreign_key: 'initiated_by'

  validates :event_id, presence: true
  validates :initiated_by, presence: true
  validates :status, inclusion: { in: %w[processing completed partial failed] }

  scope :processing, -> { where(status: 'processing') }
  scope :completed, -> { where(status: 'completed') }
  scope :partial, -> { where(status: 'partial') }

  def complete!
    if total_failed > 0
      update!(status: 'partial')
    else
      update!(status: 'completed')
    end
  end

  def record_success!(amount)
    increment!(:total_refunded)
    increment!(:total_amount_refunded, amount)
  end

  def record_failure!
    increment!(:total_failed)
  end

  def success_rate
    return 0 if total_bookings == 0
    (total_refunded.to_f / total_bookings * 100).round(1)
  end

  def summary
    {
      event: event.title,
      total_bookings: total_bookings,
      total_refunded: total_refunded,
      total_failed: total_failed,
      total_amount_refunded: total_amount_refunded,
      success_rate: "#{success_rate}%",
      status: status
    }
  end
end
