# frozen_string_literal: true

class DesPayoutService
  def initialize(event)
    @event = event
    @organisation = event.organisation
  end

  def calculate
    bookings = paid_bookings
    gross = bookings.sum(:amount_paid).to_f
    transaction_count = bookings.count
    complimentary_count = complimentary_bookings.count

    paypal_fee_percent = SiteSetting.des_paypal_fee_percent.to_f
    paypal_fee_fixed = SiteSetting.des_paypal_fee_fixed.to_f
    surcharge_percent = @organisation.surcharge_percentage.to_f

    paypal_fee_amount = ((gross * paypal_fee_percent / 100) + (transaction_count * paypal_fee_fixed)).round(2)
    surcharge_amount = (gross * surcharge_percent / 100).round(2)
    net_amount = (gross - paypal_fee_amount - surcharge_amount).round(2)

    net_amount = 0.0 if net_amount < 0

    {
      gross_amount: gross,
      transaction_count: transaction_count,
      complimentary_count: complimentary_count,
      paypal_fee_percent: paypal_fee_percent,
      paypal_fee_fixed: paypal_fee_fixed,
      paypal_fee_amount: paypal_fee_amount,
      surcharge_percent: surcharge_percent,
      surcharge_amount: surcharge_amount,
      net_amount: net_amount,
      currency: 'GBP',
      booking_breakdown: booking_breakdown(bookings)
    }
  end

  def create_or_update_payout!
    calc = calculate
    payout = DesEventPayout.find_or_initialize_by(event_id: @event.id)

    if payout.new_record? || payout.status == 'pending'
      payout.assign_attributes(
        organisation_id: @organisation.id,
        gross_amount: calc[:gross_amount],
        transaction_count: calc[:transaction_count],
        complimentary_count: calc[:complimentary_count],
        paypal_fee_percent: calc[:paypal_fee_percent],
        paypal_fee_fixed: calc[:paypal_fee_fixed],
        paypal_fee_amount: calc[:paypal_fee_amount],
        surcharge_percent: calc[:surcharge_percent],
        surcharge_amount: calc[:surcharge_amount],
        net_amount: calc[:net_amount],
        currency: calc[:currency],
        status: payout.status || 'pending'
      )
      payout.save!
    end

    payout
  end

  private

  def paid_bookings
    @event.des_event_bookings
          .where(status: 'confirmed')
          .where('amount_paid > 0')
  end

  def complimentary_bookings
    @event.des_event_bookings
          .where(status: 'confirmed')
          .where('amount_paid IS NULL OR amount_paid = 0')
  end

  def booking_breakdown(bookings)
    bookings.map do |b|
      {
        id: b.id,
        user_id: b.user_id,
        amount_paid: b.amount_paid,
        status: b.status,
        created_at: b.created_at
      }
    end
  end
end
