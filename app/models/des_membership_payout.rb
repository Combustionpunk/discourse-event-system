class DesMembershipPayout < ActiveRecord::Base
  belongs_to :organisation, class_name: 'DesOrganisation', foreign_key: 'organisation_id'

  validates :organisation_id, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }

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

  def self.calculate_for_organisation(organisation, period_start, period_end)
    payments = DesMembershipPayment
      .where(organisation_id: organisation.id, status: 'completed')
      .where(created_at: period_start..period_end)

    gross = payments.sum(:amount)
    surcharge = organisation.surcharge_percentage
    surcharge_amount = gross * (surcharge / 100)
    net = gross - surcharge_amount

    create!(
      organisation_id: organisation.id,
      period_start: period_start,
      period_end: period_end,
      gross_amount: gross,
      surcharge_percentage: surcharge,
      surcharge_amount: surcharge_amount,
      net_amount: net,
      status: 'pending'
    )
  end
end
