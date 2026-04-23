# frozen_string_literal: true

require 'net/http'
require 'json'
require 'base64'

class DesPaypalService
  SANDBOX_URL = 'https://api-m.sandbox.paypal.com'
  LIVE_URL = 'https://api-m.paypal.com'

  def initialize
    @client_id = SiteSetting.discourse_event_system_paypal_client_id
    @secret = SiteSetting.discourse_event_system_paypal_secret
    @sandbox = SiteSetting.discourse_event_system_paypal_sandbox
    @base_url = @sandbox ? SANDBOX_URL : LIVE_URL
  end

  def access_token
    uri = URI("#{@base_url}/v1/oauth2/token")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@secret}")}"
    req['Content-Type'] = 'application/x-www-form-urlencoded'
    req.body = 'grant_type=client_credentials'
    response = send_request(uri, req)
    raise "PayPal auth failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)['access_token']
  end

  def create_order(booking)
    uri = URI("#{@base_url}/v2/checkout/orders")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{access_token}"
    req['Content-Type'] = 'application/json'
    req.body = order_payload(booking).to_json
    response = send_request(uri, req)
    raise "PayPal order creation failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def create_membership_order(membership, membership_type, renewal: false)
    org = membership.organisation
    uri = URI("#{@base_url}/v2/checkout/orders")
    req = Net::HTTP::Post.new(uri)
    token = access_token
    req['Authorization'] = "Bearer #{token}"
    req['Content-Type'] = 'application/json'
    req.body = {
      intent: 'CAPTURE',
      purchase_units: [{
        amount: {
          currency_code: 'GBP',
          value: membership_type.price.to_f.round(2).to_s
        },
        description: "#{org.name} - #{membership_type.name} Membership"
      }],
      application_context: {
        return_url: renewal ? "#{Discourse.base_url}/memberships/#{membership.id}/renew-confirm" : "#{Discourse.base_url}/memberships/#{membership.id}/confirm",
        locale: "en-GB",
        landing_page: "BILLING",
        shipping_preference: "NO_SHIPPING",
        cancel_url: "#{Discourse.base_url}/memberships/#{membership.id}/cancel"
      }
    }.to_json
    response = send_request(uri, req)
    raise "PayPal order creation failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def capture_order(paypal_order_id)
    uri = URI("#{@base_url}/v2/checkout/orders/#{paypal_order_id}/capture")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{access_token}"
    req['Content-Type'] = 'application/json'
    req.body = '{}'
    response = send_request(uri, req)
    raise "PayPal capture failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def refund_payment(paypal_capture_id, amount)
    uri = URI("#{@base_url}/v2/payments/captures/#{paypal_capture_id}/refund")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{access_token}"
    req['Content-Type'] = 'application/json'
    req.body = { amount: { value: format('%.2f', amount), currency_code: 'GBP' } }.to_json
    response = send_request(uri, req)
    raise "PayPal refund failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def create_family_order(bookings, event)
    primary_booking = bookings.first
    combined_total = bookings.sum { |b| b.amount_paid.to_f }
    items = bookings.flat_map { |b| family_booking_items(b) }

    uri = URI("#{@base_url}/v2/checkout/orders")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{access_token}"
    req['Content-Type'] = 'application/json'
    req.body = {
      intent: 'CAPTURE',
      purchase_units: [
        {
          reference_id: "family_booking_#{primary_booking.id}",
          description: "#{event.title} - Family Booking",
          amount: {
            currency_code: 'GBP',
            value: format('%.2f', combined_total),
            breakdown: {
              item_total: {
                currency_code: 'GBP',
                value: format('%.2f', combined_total)
              }
            }
          },
          items: items
        }
      ],
      application_context: {
        return_url: "#{Discourse.base_url}/events/booking/#{primary_booking.id}/confirm",
        locale: "en-GB",
        landing_page: "BILLING",
        shipping_preference: "NO_SHIPPING",
        cancel_url: "#{Discourse.base_url}/events/booking/#{primary_booking.id}/cancel"
      }
    }.to_json
    response = send_request(uri, req)
    raise "PayPal order creation failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def create_payout(organisation, amount)
    uri = URI("#{@base_url}/v1/payments/payouts")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{access_token}"
    req['Content-Type'] = 'application/json'
    req.body = payout_payload(organisation, amount).to_json
    response = send_request(uri, req)
    raise "PayPal payout failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  private

  def send_request(uri, req)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
  end

  def order_payload(booking)
    {
      intent: 'CAPTURE',
      purchase_units: [
        {
          reference_id: "booking_#{booking.id}",
          description: "#{booking.event.title} - Booking ##{booking.id}",
          amount: {
            currency_code: 'GBP',
            value: format('%.2f', booking.amount_paid),
            breakdown: {
              item_total: {
                currency_code: 'GBP',
                value: format('%.2f', booking.amount_paid)
              }
            }
          },
          items: booking_items(booking)
        }
      ],
      application_context: {
        return_url: "#{Discourse.base_url}/events/booking/#{booking.id}/confirm",
        locale: "en-GB",
        landing_page: "BILLING",
        shipping_preference: "NO_SHIPPING",
        cancel_url: "#{Discourse.base_url}/events/booking/#{booking.id}/cancel"
      }
    }
  end

  def booking_items(booking)
    booking.booking_classes.map do |bc|
      {
        name: bc.event_class.name,
        quantity: '1',
        unit_amount: {
          currency_code: 'GBP',
          value: format('%.2f', bc.amount_charged)
        }
      }
    end
  end

  def family_booking_items(booking)
    booking.booking_classes.map do |bc|
      {
        name: "#{booking.user.username} - #{bc.event_class.name}",
        quantity: '1',
        unit_amount: {
          currency_code: 'GBP',
          value: format('%.2f', bc.amount_charged)
        }
      }
    end
  end

  def payout_payload(organisation, amount)
    {
      sender_batch_header: {
        sender_batch_id: "payout_org_#{organisation.id}_#{Time.now.to_i}",
        email_subject: "Payment from #{SiteSetting.title}",
        email_message: "Your event payout has been processed."
      },
      items: [
        {
          recipient_type: 'EMAIL',
          amount: {
            value: format('%.2f', amount),
            currency: 'GBP'
          },
          receiver: organisation.paypal_email,
          note: "Event payout for #{organisation.name}"
        }
      ]
    }
  end
end
