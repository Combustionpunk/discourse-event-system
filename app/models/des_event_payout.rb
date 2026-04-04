class DesEventPayout < ActiveRecord::Base
  belongs_to :event, class_name: 'DesEvent', foreign_key: 'event_id'
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'
  belongs_to :initiator, class_name: 'User', foreign_key: 'initiated_by'

  validates :event_id, presence: true
  validates :organisation_id, presence: true
  validates :initiated_by, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }

  def self.calculate_for_event(event, initiated_by)
    gross = event.des_event_bookings.confirmed.sum(:amount_paid)
    surcharge = event.organisation.surcharge_percentage
    surcharge_amount = gross * (surcharge / 100)
    net = gross - surcharge_amount

    create!(
      event_id: event.id,
      organisation_id: event.organisation_id,
      gross_amount: gross,
      surcharge_percentage: surcharge,
      surcharge_amount: surcharge_amount,
      net_amount: net,
      status: 'pending',
      initiated_by: initiated_by.id
    )
  end

  def process!(paypal_payout_id)
    update!(
      status: 'completed',
      paypal_payout_id: paypal_payout_id,
      paid_at: Time.now
    )
  end

  def fail!
    update!(status: 'failed')
  end

  def summary
    {
      event: event.title,
      organisation: organisation.name,
      gross_amount: gross_amount,
      surcharge_percentage: surcharge_percentage,
      surcharge_amount: surcharge_amount,
      net_amount: net_amount,
      status: status,
      paid_at: paid_at
    }
  end
end
