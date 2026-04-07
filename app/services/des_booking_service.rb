# frozen_string_literal: true

class DesBookingService
  def initialize(user, event)
    @user = user
    @event = event
    @paypal = DesPaypalService.new
  end

  def create_booking(class_ids, car_selections = {})
    validate_classes!(class_ids)
    # Check driver age eligibility
    class_ids.each do |class_id|
      event_class = DesEventClass.find(class_id)
      age_rules = DesClassCompatibilityRule
        .where(class_type_id: event_class.class_type_id)
        .where(rule_type: ['max_age', 'min_age'])
      age_rules.each do |rule|
        unless rule.driver_eligible?(@user)
          raise "You are not eligible for #{event_class.name} due to age restrictions"
        end
      end
    end

    booking = DesEventBooking.create!(
      event_id: @event.id,
      user_id: @user.id,
      status: 'pending'
    )

    class_ids.each do |class_id|
      event_class = DesEventClass.find(class_id)
      raise "#{event_class.name} is full" if event_class.sold_out?

      booking_class = DesEventBookingClass.create!(
        booking_id: booking.id,
        event_class_id: class_id,
        status: 'confirmed'
      )
      booking_class.assign_transponder(@user)
    end

    total = booking.calculate_total
    paypal_response = @paypal.create_order(booking)
    paypal_order_id = paypal_response['id']
    approval_url = paypal_response['links'].find { |l| l['rel'] == 'approve' }['href']

    DesEventBookingPayment.create!(
      booking_id: booking.id,
      amount: total,
      paypal_order_id: paypal_order_id,
      payment_type: 'initial',
      status: 'pending'
    )

    booking.update!(paypal_order_id: paypal_order_id)
    { booking: booking, approval_url: approval_url }
  rescue => e
    booking&.destroy
    raise e
  end

  def create_family_booking(primary_class_ids, family_bookings, car_selections = {})
    # family_bookings is an array of { user_id:, class_ids: }
    validate_classes!(primary_class_ids)
    family_bookings.each { |fb| validate_classes!(fb[:class_ids]) }

    all_bookings = []

    # Create primary booking
    primary_booking = create_single_booking(@user, primary_class_ids, car_selections)
    all_bookings << primary_booking

    # Create family member bookings
    family_bookings.each do |fb|
      family_user = User.find(fb[:user_id])
      booking = create_single_booking(family_user, fb[:class_ids], {}, booked_by: @user)
      all_bookings << booking
    end

    # Calculate combined total
    combined_total = all_bookings.sum { |b| b.calculate_total }

    # Create one PayPal order for the combined total
    paypal_response = @paypal.create_family_order(all_bookings, @event)
    paypal_order_id = paypal_response['id']
    approval_url = paypal_response['links'].find { |l| l['rel'] == 'approve' }['href']

    # Create payment records and store paypal_order_id on all bookings
    all_bookings.each do |booking|
      DesEventBookingPayment.create!(
        booking_id: booking.id,
        amount: booking.amount_paid,
        paypal_order_id: paypal_order_id,
        payment_type: 'initial',
        status: 'pending'
      )
      booking.update!(paypal_order_id: paypal_order_id)
    end

    { booking: primary_booking, all_bookings: all_bookings, approval_url: approval_url }
  rescue => e
    all_bookings&.each { |b| b&.destroy }
    raise e
  end

  def confirm_booking(booking, paypal_order_id)
    payment = booking.payments.find_by(paypal_order_id: paypal_order_id)
    raise "Payment not found" unless payment
    capture_response = @paypal.capture_order(paypal_order_id)
    capture_id = capture_response.dig('purchase_units', 0, 'payments', 'captures', 0, 'id')
    raise "Capture failed" unless capture_id
    payment.complete!(capture_id)
    booking.update!(status: 'confirmed')

    # Confirm all linked family bookings with the same paypal_order_id
    linked_bookings = DesEventBooking.where(paypal_order_id: paypal_order_id).where.not(id: booking.id)
    linked_bookings.each do |linked|
      linked_payment = linked.payments.find_by(paypal_order_id: paypal_order_id)
      linked_payment&.complete!(capture_id)
      linked.update!(status: 'confirmed')
    end

    # Only send confirmation email to the parent/primary user
    begin
      DiscourseEventSystem::EventMailer.booking_confirmed(booking).deliver_later
    rescue => e
      Rails.logger.error "Failed to send booking confirmed email: #{e.message}"
    end

    booking
  end

  def cancel_booking(booking)
    booking.cancel!
    booking.payments.pending.each(&:fail!)

    begin
      DiscourseEventSystem::EventMailer.booking_cancelled(booking).deliver_later
    rescue => e
      Rails.logger.error "Failed to send booking cancelled email: #{e.message}"
    end

    booking
  end

  def add_classes(booking, class_ids)
    raise "Booking is not confirmed" unless booking.status == 'confirmed'

    class_ids.each do |class_id|
      event_class = DesEventClass.find(class_id)
      raise "#{event_class.name} is full" if event_class.sold_out?
      raise "Already booked into #{event_class.name}" if booking.booking_classes.exists?(event_class_id: class_id)

      booking_class = DesEventBookingClass.create!(
        booking_id: booking.id,
        event_class_id: class_id,
        status: 'confirmed'
      )
      booking_class.assign_transponder(@user)
    end

    new_total = booking.calculate_total
    previous_paid = booking.payments.completed.sum(:amount)
    additional_amount = new_total - previous_paid

    if additional_amount > 0
      paypal_response = @paypal.create_order(booking)
      paypal_order_id = paypal_response['id']
      approval_url = paypal_response['links'].find { |l| l['rel'] == 'approve' }['href']

      DesEventBookingPayment.create!(
        booking_id: booking.id,
        amount: additional_amount,
        paypal_order_id: paypal_order_id,
        payment_type: 'additional',
        status: 'pending'
      )

      { booking: booking, approval_url: approval_url }
    else
      { booking: booking, approval_url: nil }
    end
  end

  def refund_booking(booking, initiated_by, reason = nil)
    raise "Booking is not refundable" unless booking.refundable?

    booking.payments.completed.each do |payment|
      refund_amount = payment.refundable_amount
      next if refund_amount <= 0

      paypal_response = @paypal.refund_payment(payment.paypal_capture_id, refund_amount)
      paypal_refund_id = paypal_response['id']

      DesEventBookingRefund.create!(
        booking_id: booking.id,
        payment_id: payment.id,
        amount: refund_amount,
        reason: reason,
        status: 'completed',
        paypal_refund_id: paypal_refund_id,
        event_cancellation: false,
        initiated_by: initiated_by.id
      ).complete!(paypal_refund_id)
    end

    booking.reload

    begin
      DiscourseEventSystem::EventMailer.booking_cancelled(booking, reason).deliver_later
    rescue => e
      Rails.logger.error "Failed to send booking cancelled email: #{e.message}"
    end

    booking
  end

  def cancel_event_and_refund(cancellation_reason, initiated_by)
    @event.cancel!(cancellation_reason)

    confirmed_bookings = @event.des_event_bookings.confirmed
    cancellation_record = DesEventCancellationRefund.create!(
      event_id: @event.id,
      initiated_by: initiated_by.id,
      total_bookings: confirmed_bookings.count,
      status: 'processing'
    )

    confirmed_bookings.each do |booking|
      begin
        # Send event cancellation email
        begin
          DiscourseEventSystem::EventMailer.event_cancelled(booking, cancellation_reason).deliver_later
        rescue => e
          Rails.logger.error "Failed to send event cancellation email: #{e.message}"
        end
        booking.cancel!
        booking.payments.completed.each do |payment|
          refund_amount = payment.refundable_amount
          next if refund_amount <= 0

          paypal_response = @paypal.refund_payment(payment.paypal_capture_id, refund_amount)
          paypal_refund_id = paypal_response['id']

          DesEventBookingRefund.create!(
            booking_id: booking.id,
            payment_id: payment.id,
            amount: refund_amount,
            reason: "Event cancelled: #{cancellation_reason}",
            status: 'completed',
            paypal_refund_id: paypal_refund_id,
            event_cancellation: true,
            initiated_by: initiated_by.id
          ).complete!(paypal_refund_id)

          cancellation_record.record_success!(refund_amount)
        end
      rescue => e
        cancellation_record.record_failure!
      end
    end

    cancellation_record.complete!
    cancellation_record
  end

  def process_payout(initiated_by)
    raise "Event is not completed" unless @event.status == 'completed'
    raise "Payout already exists" if DesEventPayout.exists?(event_id: @event.id)

    payout = DesEventPayout.calculate_for_event(@event, initiated_by)

    paypal_response = @paypal.create_payout(@event.organisation, payout.net_amount)
    paypal_payout_id = paypal_response.dig('batch_header', 'payout_batch_id')

    payout.process!(paypal_payout_id)
    payout
  end

  private

  def create_single_booking(user, class_ids, car_selections = {}, booked_by: nil)
    class_ids.each do |class_id|
      event_class = DesEventClass.find(class_id)
      age_rules = DesClassCompatibilityRule
        .where(class_type_id: event_class.class_type_id)
        .where(rule_type: ['max_age', 'min_age'])
      age_rules.each do |rule|
        unless rule.driver_eligible?(user)
          raise "#{user.username} is not eligible for #{event_class.name} due to age restrictions"
        end
      end
    end

    booking = DesEventBooking.create!(
      event_id: @event.id,
      user_id: user.id,
      booked_by_user_id: booked_by&.id,
      status: 'pending'
    )

    class_ids.each do |class_id|
      event_class = DesEventClass.find(class_id)
      raise "#{event_class.name} is full" if event_class.sold_out?

      booking_class = DesEventBookingClass.create!(
        booking_id: booking.id,
        event_class_id: class_id,
        status: 'confirmed'
      )
      booking_class.assign_transponder(user, car_owner: booked_by)
    end

    booking
  end

  def validate_classes!(class_ids)
    raise "Please select at least one class" if class_ids.empty?
    if @event.max_classes_per_booking.present? && class_ids.length > @event.max_classes_per_booking
      raise "You can only book a maximum of #{@event.max_classes_per_booking} class(es) for this event"
    end
    class_ids.each do |class_id|
      event_class = DesEventClass.find_by(id: class_id)
      raise "Invalid class selected" unless event_class
      raise "Class does not belong to this event" unless event_class.event_id == @event.id
    end
  end
end
