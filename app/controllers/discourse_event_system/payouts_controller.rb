# frozen_string_literal: true

module DiscourseEventSystem
  class PayoutsController < ApplicationController
    before_action :ensure_logged_in
    before_action :set_event, only: [:show, :approve, :claim, :retry]

    def show
      ensure_organisation_admin!(@event.organisation)
      service = DesPayoutService.new(@event)
      calc = service.calculate
      payout = @event.des_event_payout

      render json: {
        payout: payout ? serialize_payout(payout) : nil,
        calculation: calc
      }
    end

    def approve
      ensure_admin!
      payout = DesPayoutService.new(@event).create_or_update_payout!

      unless @event.organisation.paypal_email.present?
        return render json: { error: 'Organisation has no PayPal email set.' }, status: :unprocessable_entity
      end

      unless payout.status == 'pending'
        return render json: { error: "Cannot approve payout with status: #{payout.status}" }, status: :unprocessable_entity
      end

      payout.update!(
        status: 'approved',
        approved_by_user_id: current_user.id,
        approved_at: Time.now,
        paypal_email_snapshot: @event.organisation.paypal_email,
        surcharge_percent: @event.organisation.surcharge_percentage,
        paypal_fee_percent: SiteSetting.des_paypal_fee_percent,
        paypal_fee_fixed: SiteSetting.des_paypal_fee_fixed
      )

      notify_org_admins(@event.organisation, @event, payout)
      render json: { payout: serialize_payout(payout) }
    end

    def claim
      ensure_organisation_admin!(@event.organisation)
      payout = @event.des_event_payout

      return render json: { error: 'No payout found' }, status: :not_found unless payout
      return render json: { error: 'Payout not yet approved' }, status: :unprocessable_entity unless payout.status == 'approved'

      payout.update!(status: 'claimed', claimed_at: Time.now)

      result = trigger_paypal_payout(payout)

      if result[:success]
        payout.update!(
          status: 'paid',
          paid_at: Time.now,
          paypal_payout_batch_id: result[:batch_id],
          paypal_payout_item_id: result[:item_id]
        )
        notify_site_admins_payout_complete(payout)
        render json: { payout: serialize_payout(payout), message: 'Payout sent successfully' }
      else
        payout.update!(status: 'failed', failure_reason: result[:error])
        notify_site_admins_payout_failed(payout)
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def retry
      ensure_organisation_admin!(@event.organisation)
      payout = @event.des_event_payout
      return render json: { error: 'No payout found' }, status: :not_found unless payout
      return render json: { error: 'Can only retry failed payouts' }, status: :unprocessable_entity unless payout.status == 'failed'

      payout.update!(status: 'claimed', claimed_at: Time.now, failure_reason: nil)

      result = trigger_paypal_payout(payout)

      if result[:success]
        payout.update!(
          status: 'paid',
          paid_at: Time.now,
          paypal_payout_batch_id: result[:batch_id],
          paypal_payout_item_id: result[:item_id]
        )
        notify_site_admins_payout_complete(payout)
        render json: { payout: serialize_payout(payout), message: 'Payout sent successfully' }
      else
        payout.update!(status: 'failed', failure_reason: result[:error])
        notify_site_admins_payout_failed(payout)
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def admin_index
      ensure_admin!

      payouts = DesEventPayout.includes(:des_event, :organisation).order(created_at: :desc)

      case params[:period]
      when '7days'
        payouts = payouts.where('des_event_payouts.created_at > ?', 7.days.ago)
      when 'month'
        payouts = payouts.where('des_event_payouts.created_at > ?', 1.month.ago)
      when 'year'
        payouts = payouts.where('des_event_payouts.created_at > ?', 1.year.ago)
      end

      total_gross = payouts.sum(:gross_amount)
      total_surcharge = payouts.sum(:surcharge_amount)
      total_paid = payouts.where(status: 'paid').sum(:net_amount)
      total_unclaimed = payouts.where(status: 'approved').sum(:net_amount)

      render json: {
        payouts: payouts.map { |p| serialize_payout(p) },
        summary: {
          total_gross: total_gross,
          total_surcharge: total_surcharge,
          total_paid: total_paid,
          total_unclaimed: total_unclaimed,
          pending_count: payouts.pending.count,
          approved_count: payouts.approved.count,
          claimed_count: payouts.claimed.count
        }
      }
    end

    def org_index
      org = DesOrganisation.find(params[:id])
      ensure_organisation_admin!(org)

      payouts = DesEventPayout.includes(:des_event)
                              .where(organisation_id: org.id)
                              .order(created_at: :desc)

      render json: {
        payouts: payouts.map { |p| serialize_payout(p) },
        summary: {
          total_paid: payouts.where(status: 'paid').sum(:net_amount),
          total_pending: payouts.where(status: %w[pending approved claimed]).sum(:net_amount)
        }
      }
    end

    private

    def set_event
      @event = DesEvent.includes(:organisation, :des_event_bookings).find(params[:id])
    end

    def ensure_admin!
      raise Discourse::InvalidAccess unless current_user&.admin?
    end

    def ensure_organisation_admin!(org)
      raise Discourse::InvalidAccess unless current_user&.admin? ||
        DesOrganisationMember.exists?(
          organisation_id: org.id,
          user_id: current_user.id,
          status: 'active'
        )
    end

    def trigger_paypal_payout(payout)
      require 'net/http'
      require 'json'

      begin
        token_response = get_paypal_access_token
        return { success: false, error: 'Failed to get PayPal access token' } unless token_response[:success]

        access_token = token_response[:token]
        sandbox = SiteSetting.respond_to?(:discourse_event_system_paypal_sandbox) && SiteSetting.discourse_event_system_paypal_sandbox
        base_url = sandbox ? 'https://api-m.sandbox.paypal.com' : 'https://api-m.paypal.com'

        uri = URI("#{base_url}/v1/payments/payouts")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{access_token}"
        request['Content-Type'] = 'application/json'
        request.body = {
          sender_batch_header: {
            sender_batch_id: "payout_#{payout.id}_#{Time.now.to_i}",
            email_subject: "Event Payout: #{payout.des_event.title}",
            email_message: "Your payout for #{payout.des_event.title} has been processed."
          },
          items: [{
            recipient_type: 'EMAIL',
            amount: {
              value: payout.net_amount.to_s,
              currency: payout.currency
            },
            receiver: payout.paypal_email_snapshot,
            note: "Payout for #{payout.des_event.title}",
            sender_item_id: "event_#{payout.event_id}"
          }]
        }.to_json

        response = http.request(request)
        data = JSON.parse(response.body)

        if response.code == '201'
          batch_id = data.dig('batch_header', 'payout_batch_id')
          item_id = data.dig('items', 0, 'payout_item_id')
          { success: true, batch_id: batch_id, item_id: item_id }
        else
          { success: false, error: data['message'] || 'PayPal payout failed' }
        end
      rescue => e
        { success: false, error: e.message }
      end
    end

    def get_paypal_access_token
      require 'net/http'
      require 'base64'

      client_id = SiteSetting.respond_to?(:des_paypal_client_id) ? SiteSetting.des_paypal_client_id : ''
      client_secret = SiteSetting.respond_to?(:des_paypal_client_secret) ? SiteSetting.des_paypal_client_secret : ''

      sandbox = SiteSetting.respond_to?(:discourse_event_system_paypal_sandbox) && SiteSetting.discourse_event_system_paypal_sandbox
      base_url = sandbox ? 'https://api-m.sandbox.paypal.com' : 'https://api-m.paypal.com'

      uri = URI("#{base_url}/v1/oauth2/token")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = 'grant_type=client_credentials'

      response = http.request(request)
      data = JSON.parse(response.body)

      if response.code == '200'
        { success: true, token: data['access_token'] }
      else
        { success: false, error: 'Auth failed' }
      end
    rescue => e
      { success: false, error: e.message }
    end

    def notify_org_admins(org, event, payout)
      DesOrganisationMember.where(organisation_id: org.id, status: 'active').each do |member|
        Notification.create(
          notification_type: (Notification.types[:custom] || Notification.types[:posted]),
          user_id: member.user_id,
          high_priority: true,
          topic_id: event.topic_id,
          post_number: 1,
          data: {
            message: "💰 Payout approved for #{event.title}",
            display_username: "Payment Available",
            topic_title: event.title,
            url: event.topic_id ? "/t/#{event.topic_id}" : "/events"
          }.to_json
        )
      end
    end

    def notify_site_admins_payout_complete(payout)
      User.where(admin: true).each do |admin|
        Notification.create(
          notification_type: (Notification.types[:custom] || Notification.types[:posted]),
          user_id: admin.id,
          high_priority: true,
          data: {
            message: "✅ Payout of £#{payout.net_amount} sent to #{payout.organisation.name}",
            display_username: "PayPal",
            topic_title: payout.des_event.title,
            url: "/des-admin"
          }.to_json
        )
      end
    end

    def notify_site_admins_payout_failed(payout)
      User.where(admin: true).each do |admin|
        Notification.create(
          notification_type: (Notification.types[:custom] || Notification.types[:posted]),
          user_id: admin.id,
          high_priority: true,
          data: {
            message: "❌ Payout FAILED for #{payout.des_event.title}: #{payout.failure_reason}",
            display_username: "PayPal",
            topic_title: payout.des_event.title,
            url: "/des-admin"
          }.to_json
        )
      end
    end

    def serialize_payout(payout)
      {
        id: payout.id,
        event_id: payout.event_id,
        event_title: payout.des_event&.title,
        event_date: payout.des_event&.start_date&.strftime('%d %b %Y'),
        organisation_id: payout.organisation_id,
        organisation_name: payout.organisation&.name,
        gross_amount: payout.gross_amount,
        transaction_count: payout.transaction_count,
        complimentary_count: payout.complimentary_count,
        paypal_fee_percent: payout.paypal_fee_percent,
        paypal_fee_fixed: payout.paypal_fee_fixed,
        paypal_fee_amount: payout.paypal_fee_amount,
        surcharge_percent: payout.surcharge_percent,
        surcharge_amount: payout.surcharge_amount,
        net_amount: payout.net_amount,
        currency: payout.currency,
        status: payout.status,
        approved_at: payout.approved_at,
        claimed_at: payout.claimed_at,
        paid_at: payout.paid_at,
        paypal_email_snapshot: payout.paypal_email_snapshot,
        failure_reason: payout.failure_reason,
        created_at: payout.created_at
      }
    end
  end
end
