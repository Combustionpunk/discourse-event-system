# frozen_string_literal: true

require 'net/http'

module DiscourseEventSystem
  class EventsController < ApplicationController
    before_action :ensure_logged_in, except: [:index, :show, :public_entrants, :rc_topic_list, :geocode_postcode_endpoint]
    before_action :set_event, only: [:show, :update, :update_pricing, :publish, :cancel, :clone, :destroy, :update_booking_status, :subscribe_booking_alert, :unsubscribe_booking_alert, :entrants, :public_entrants, :export_csv, :add_class, :update_class, :toggle_class_status, :cancel_entrant, :delete_booking, :change_entrant_car, :move_entrant_class, :sync_transponders, :destroy_class, :remove_from_waitlist]

    def index
      if current_user&.admin?
        events = DesEvent.includes(:organisation, :event_type, :des_event_classes, :venue)
      else
        events = DesEvent.published.includes(:organisation, :event_type, :des_event_classes, :venue)
      end

      # Filter by time
      case params[:filter]
      when 'past'
        events = events.where('start_date < ?', Time.now).order(start_date: :desc)
      else
        if current_user&.admin?
          events = events.where('start_date > ?', Time.now).order(start_date: :asc)
        else
          events = events.upcoming.order(start_date: :asc)
        end
      end

      # Filter by organisation
      events = events.where(organisation_id: params[:organisation_id]) if params[:organisation_id].present?

      # Filter by event type
      events = events.where(event_type_id: params[:event_type_id]) if params[:event_type_id].present?

      # Include organisations and event types for filter dropdowns
      organisations = DesOrganisation.approved.order(:name)
      event_types = DesEventType.all.order(:name)

      render json: {
        events: serialize_events(events),
        organisations: organisations.map { |o| { id: o.id, name: o.name, logo_url: o.logo_url } },
        event_types: event_types.map { |et| { id: et.id, name: et.name } }
      }
    end

    def by_topic
      event = DesEvent.find_by(topic_id: params[:topic_id])
      return render json: { error: 'Not found' }, status: :not_found unless event
      render json: serialize_event(event)
    end

    def class_types
      render json: {
        class_types: DesEventClassType.all.order(:name).map { |ct|
          {
            id: ct.id,
            name: ct.name,
            track_environment: ct.track_environment,
            scale: ct.scale,
            chassis_types: ct.chassis_types_list,
            drivelines: ct.drivelines_list
          }
        }
      }
    end

    def event_types
      render json: {
        event_types: DesEventType.all.order(:name).map { |et| { id: et.id, name: et.name } }
      }
    end

    def event_types
      render json: {
        event_types: DesEventType.all.order(:name).map { |et| { id: et.id, name: et.name } }
      }
    end

    def rc_topic_list
      events = DesEvent.includes(:organisation, :venue, des_event_classes: :class_type)
                       .where.not(topic_id: nil)
                       .where.not(status: ['cancelled', 'draft'])

      case params[:time_filter]
      when 'past'
        events = events.where('start_date < ?', Time.now.beginning_of_day).order(start_date: :desc)
      when 'today'
        events = events.where('start_date >= ? AND start_date < ?', Time.now.beginning_of_day, Time.now.end_of_day).order(start_date: :asc)
      when 'upcoming'
        events = events.where('start_date > ?', Time.now.end_of_day).order(start_date: :asc)
      when 'all'
        events = events.order(start_date: :asc)
      else
        today    = events.where('start_date >= ? AND start_date < ?', Time.now.beginning_of_day, Time.now.end_of_day).order(start_date: :asc)
        upcoming = events.where('start_date > ?', Time.now.end_of_day).order(start_date: :asc)
        past     = events.where('start_date < ?', Time.now.beginning_of_day).order(start_date: :desc)

        today    = today.where(organisation_id: params[:organisation_id]) if params[:organisation_id].present?
        upcoming = upcoming.where(organisation_id: params[:organisation_id]) if params[:organisation_id].present?
        past     = past.where(organisation_id: params[:organisation_id]) if params[:organisation_id].present?

        today    = today.where(event_type_id: params[:event_type_id]) if params[:event_type_id].present?
        upcoming = upcoming.where(event_type_id: params[:event_type_id]) if params[:event_type_id].present?
        past     = past.where(event_type_id: params[:event_type_id]) if params[:event_type_id].present?

        today_arr    = apply_venue_filters(today, params).to_a
        upcoming_arr = apply_venue_filters(upcoming, params).to_a
        past_arr     = apply_venue_filters(past, params).to_a

        topics = case params[:time_filter]
        when 'past'
          past_arr
        when 'today'
          today_arr
        when 'all'
          today_arr + upcoming_arr + past_arr
        else
          today_arr + upcoming_arr
        end.map { |e| serialize_rc_topic(e) }
        topics = filter_by_distance(topics, params[:postcode], params[:max_distance_miles]) if params[:postcode].present?
        topics = apply_scale_power_filters(topics, params)
        imported = fetch_imported_events(params)
        return render json: { topics: topics, imported_events: imported, filters: rc_filter_options }
      end

      events = events.where(organisation_id: params[:organisation_id]) if params[:organisation_id].present?
      events = events.where(event_type_id: params[:event_type_id]) if params[:event_type_id].present?
      events = apply_venue_filters(events, params)

      topics = events.map { |e| serialize_rc_topic(e) }
      topics = filter_by_distance(topics, params[:postcode], params[:max_distance_miles]) if params[:postcode].present?
      topics = apply_scale_power_filters(topics, params)
      imported = fetch_imported_events(params)
      render json: {
        topics: topics,
        imported_events: imported,
        filters: rc_filter_options
      }
    end

    def geocode_postcode_endpoint
      result = geocode_postcode(params[:postcode])
      if result
        render json: { success: true, lat: result[:lat], lng: result[:lng] }
      else
        render json: { success: false, error: 'Invalid postcode' }, status: :unprocessable_entity
      end
    end

    def subscribe_booking_alert
      return render json: { error: 'Booking is already open' }, status: :unprocessable_entity if @event.booking_open?
      DesEventBookingAlert.find_or_create_by!(user_id: current_user.id, event_id: @event.id)
      render json: { subscribed: true }
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def unsubscribe_booking_alert
      DesEventBookingAlert.where(user_id: current_user.id, event_id: @event.id).destroy_all
      render json: { subscribed: false }
    end

    def show
      render json: serialize_event(@event)
    end

    def create
      organisation = DesOrganisation.find(params[:organisation_id])
      ensure_organisation_admin!(organisation)

      ActiveRecord::Base.transaction do
        event = DesEvent.new(event_params)
        event.created_by = current_user.id
        event.status = 'draft'
        event.save!

        # Create classes
        classes_array = params[:classes].present? ? params[:classes].values : []
        classes_array.each do |cls|
          class_type = DesEventClassType.find(cls[:class_type_id])
          DesEventClass.create!(
            event_id: event.id,
            class_type_id: cls[:class_type_id],
            name: class_type.name,
            capacity: cls[:capacity].to_i,
            status: 'active'
          )
        end

        # Create pricing rule
        if params[:pricing].present?
          DesEventPricingRule.create!(
            event_id: event.id,
            rule_type: params[:pricing][:rule_type],
            flat_price: params[:pricing][:flat_price],
            first_class_price: params[:pricing][:first_class_price],
            subsequent_class_price: params[:pricing][:subsequent_class_price],
            member_first_class_discount: params[:pricing][:member_first_class_discount],
            member_subsequent_discount: params[:pricing][:member_subsequent_discount],
            junior_first_class_discount: params[:pricing][:junior_first_class_discount],
            junior_subsequent_discount: params[:pricing][:junior_subsequent_discount]
          )
        end

        render json: serialize_event(event.reload), status: :created
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_pricing
      ensure_organisation_admin!(@event.organisation)
      pricing = @event.des_event_pricing_rule || DesEventPricingRule.new(event_id: @event.id)
      pricing.update!(
        rule_type: params[:pricing][:rule_type],
        flat_price: params[:pricing][:flat_price],
        first_class_price: params[:pricing][:first_class_price],
        subsequent_class_price: params[:pricing][:subsequent_class_price],
        member_first_class_discount: params[:pricing][:member_first_class_discount],
        member_subsequent_discount: params[:pricing][:member_subsequent_discount],
        junior_first_class_discount: params[:pricing][:junior_first_class_discount],
        junior_subsequent_discount: params[:pricing][:junior_subsequent_discount]
      )
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update
      ensure_organisation_admin!(@event.organisation)
      # Track what changed for email notification
      changes = {}
      [:title, :start_date, :end_date, :location].each do |field|
        old_val = @event.send(field)
        new_val = event_params[field]
        if new_val.present? && old_val.to_s != new_val.to_s
          changes[field] = { from: old_val, to: new_val }
        end
      end

      if @event.update(event_params)
        @event.update_topic_content! if @event.topic_id.present?

        # Send update emails if significant changes
        if changes.any?
          bookings = DesEventBooking.where(event_id: @event.id)
    
          bookings.each do |booking|
            begin
              DiscourseEventSystem::EventMailer.event_updated(booking, changes).deliver_later
            rescue => e
              Rails.logger.error "Failed to send event update email: #{e.message}"
            end
          end
        end

        render json: serialize_event(@event)
      else
        render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def publish
      ensure_organisation_admin!(@event.organisation)
      @event.publish!
      render json: serialize_event(@event)
    end

    def export_csv
      ensure_logged_in
      ensure_organisation_admin!(@event.organisation)
      bookings = DesEventBooking.where(event_id: @event.id)
        .includes(:user, booking_classes: { event_class: :class_type })


      csv_data = CSV.generate(headers: true) do |csv|
        csv << ['Name', 'BRCA Number', 'Class', 'PT No', 'Car Make', 'Paid Status', 'Formula Number', 'Member Type Number']
        bookings.each do |booking|
          booking.booking_classes.each do |bc|
            car = bc.car_id.present? ? bc.user_car : nil
            manufacturer = car&.manufacturer&.name || ''
            f_grade = UserCustomField.find_by(user_id: booking.user_id, name: 'des_f_grade')&.value || '0'

            # Member Type: 1=junior member, 2=adult member, 3=non-member
            is_member = DesOrganisationMembership
              .where(user_id: booking.user_id, organisation_id: @event.organisation_id)
              .active.exists?
            dob_str = UserCustomField.find_by(user_id: booking.user_id, name: 'des_date_of_birth')&.value.presence
            dob = dob_str ? Date.parse(dob_str) : booking.user.date_of_birth
            is_junior = if dob.present?
              age = @event.start_date.year - dob.year
              age -= 1 if @event.start_date < dob + age.years
              age < 16
            else
              false
            end
            member_type = if is_member && is_junior
              '1'
            elsif is_member && !is_junior
              '2'
            elsif !is_member && is_junior
              '3'
            else
              '4'
            end

            csv << [
              booking.user.name.present? ? booking.user.name : booking.user.username,
              booking.brca_membership_number.presence || '0',
              bc.event_class.name,
              bc.transponder_number.presence || '0',
              manufacturer,
              booking.status == 'confirmed' ? '1' : '0',
              f_grade,
              member_type
            ]
          end
        end
      end
      send_data csv_data,
        filename: "#{@event.title.parameterize}-entries.csv",
        type: 'text/csv',
        disposition: 'attachment'
    end

    def entrants
      ensure_organisation_admin!(@event.organisation)
      bookings = DesEventBooking.where(event_id: @event.id)
        .includes(:user, booking_classes: [:event_class, { user_car: [:manufacturer, :car_model] }])

      waitlist_entries = DesEventWaitlist.where(event_id: @event.id, status: 'waiting')
        .includes(:user)

      status_order = { 'confirmed' => 0, 'pending' => 1, 'waitlist' => 2, 'cancelled' => 3 }

      render json: {
        event: { id: @event.id, title: @event.title },
        classes: @event.des_event_classes.map do |ec|
          class_bookings = bookings.select { |b|
            b.booking_classes.any? { |bc| bc.event_class_id == ec.id }
          }
          class_waitlist = waitlist_entries.select { |w| w.event_class_id == ec.id }

          entrants = class_bookings.map do |b|
            bc = b.booking_classes.find { |bc| bc.event_class_id == ec.id }
            car = bc&.user_car
            {
              booking_id: b.id,
              booking_class_id: bc&.id,
              event_class_id: ec.id,
              username: b.user.username,
              name: b.user.name,
              user_id: b.user_id,
              avatar_template: b.user.avatar_template&.gsub('{'+'size}', '32'),
              transponder: bc&.transponder_number,
              manufacturer_name: car&.manufacturer&.name,
              model_name: car&.car_model&.name || car&.custom_model_name,
              status: b.status,
              booking_class_status: bc&.status,
              brca_number: b.brca_membership_number
            }
          end

          class_waitlist.each do |w|
            entrants << {
              booking_id: nil,
              booking_class_id: nil,
              event_class_id: ec.id,
              username: w.user.username,
              name: w.user.name,
              user_id: w.user_id,
              avatar_template: w.user.avatar_template&.gsub('{'+'size}', '32'),
              transponder: nil,
              manufacturer_name: nil,
              model_name: nil,
              status: 'waitlist',
              booking_class_status: nil,
              brca_number: nil,
              waitlist_id: w.id,
              waitlist_position: w.position
            }
          end

          entrants.sort_by! { |e| [status_order[e[:status]] || 99, e[:username]] }

          {
            id: ec.id,
            name: ec.name,
            capacity: ec.capacity,
            spaces_remaining: ec.spaces_remaining,
            entrants: entrants
          }
        end
      }
    end

    def public_entrants
      bookings = DesEventBooking.where(event_id: @event.id, status: ['confirmed', 'pending'])
        .includes(:user, booking_classes: [:event_class, { user_car: [:manufacturer, :car_model] }])

      waitlist_entries = DesEventWaitlist.where(event_id: @event.id, status: 'waiting')
        .includes(:user)

      render json: {
        classes: @event.des_event_classes.map do |ec|
          class_bookings = bookings.select { |b|
            b.booking_classes.any? { |bc| bc.event_class_id == ec.id }
          }
          class_waitlist = waitlist_entries.select { |w| w.event_class_id == ec.id }

          entrants = class_bookings.map do |b|
            bc = b.booking_classes.find { |bc| bc.event_class_id == ec.id }
            car = bc&.user_car
            {
              username: b.user.username,
              name: b.user.name,
              user_id: b.user_id,
              avatar_template: b.user.avatar_template&.gsub('{'+'size}', '32'),
              transponder: bc&.transponder_number,
              manufacturer_name: car&.manufacturer&.name,
              model_name: car&.car_model&.name || car&.custom_model_name,
              status: b.status,
              brca_number: b.brca_membership_number
            }
          end

          class_waitlist.each do |w|
            entrants << {
              username: w.user.username,
              name: w.user.name,
              user_id: w.user_id,
              avatar_template: w.user.avatar_template&.gsub('{'+'size}', '32'),
              transponder: nil,
              manufacturer_name: nil,
              model_name: nil,
              status: 'waitlist',
              brca_number: nil,
              waitlist_position: w.position
            }
          end

          {
            id: ec.id,
            name: ec.name,
            entrants: entrants
          }
        end
      }
    end


    def cancel
      ensure_organisation_admin!(@event.organisation)
      service = DesBookingService.new(current_user, @event)
      result = service.cancel_event_and_refund(params[:reason], current_user)
      render json: { event: serialize_event(@event), refund_summary: result.summary }
    end

    def destroy
      ensure_organisation_admin!(@event.organisation)
      unless ['draft', 'cancelled'].include?(@event.status)
        return render json: { error: 'Only draft or cancelled events can be deleted' }, status: :unprocessable_entity
      end
      @event.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def clone
      ensure_organisation_admin!(@event.organisation)

      new_title = params[:title].to_s.strip
      new_start_date = params[:start_date]

      return render json: { error: "Title is required" }, status: :unprocessable_entity if new_title.blank?
      return render json: { error: "Start date is required" }, status: :unprocessable_entity if new_start_date.blank?

      new_event = DesEvent.create!(
        organisation_id: @event.organisation_id,
        event_type_id: @event.event_type_id,
        venue_id: @event.venue_id,
        title: new_title,
        description: @event.description,
        start_date: new_start_date,
        end_date: @event.end_date ? (Time.parse(new_start_date) + (@event.end_date - @event.start_date)) : nil,
        location: @event.location,
        google_maps_url: @event.google_maps_url,
        capacity: @event.capacity,
        refund_cutoff_days: @event.refund_cutoff_days,
        booking_type: @event.booking_type,
        external_booking_url: @event.external_booking_url,
        external_booking_details: @event.external_booking_details,
        max_classes_per_booking: @event.max_classes_per_booking,
        booking_opens_days_before: @event.booking_opens_days_before,
        booking_closes_days_before: @event.booking_closes_days_before,
        status: 'draft',
        created_by: current_user.id
      )

      @event.des_event_classes.each do |cls|
        new_event.des_event_classes.create!(
          class_type_id: cls.class_type_id,
          name: cls.name,
          capacity: cls.capacity,
          status: cls.status
        )
      end

      if @event.des_event_pricing_rule
        pr = @event.des_event_pricing_rule
        DesEventPricingRule.create!(
          event_id: new_event.id,
          rule_type: pr.rule_type,
          flat_price: pr.flat_price,
          first_class_price: pr.first_class_price,
          subsequent_class_price: pr.subsequent_class_price,
          member_first_class_discount: pr.member_first_class_discount,
          member_subsequent_discount: pr.member_subsequent_discount,
          junior_first_class_discount: pr.junior_first_class_discount,
          junior_subsequent_discount: pr.junior_subsequent_discount
        )
      end

      render json: { success: true, event_id: new_event.id }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_booking_status
      ensure_organisation_admin!(@event.organisation)
      @event.update!(
        booking_manually_closed: params[:booking_manually_closed],
        booking_manually_open: params[:booking_manually_open]
      )
      render json: { success: true, booking_open: @event.booking_open? }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def add_class
      ensure_organisation_admin!(@event.organisation)
      class_type = DesEventClassType.find(params[:class_type_id])
      event_class = DesEventClass.create!(
        event_id: @event.id,
        class_type_id: class_type.id,
        name: class_type.name,
        capacity: params[:capacity].to_i,
        status: 'active'
      )
      render json: serialize_class(event_class), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_class
      ensure_organisation_admin!(@event.organisation)
      event_class = @event.des_event_classes.find(params[:class_id])
      event_class.update!(capacity: params[:capacity].to_i)
      event_class.update_status!
      render json: serialize_class(event_class)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def toggle_class_status
      ensure_organisation_admin!(@event.organisation)
      event_class = @event.des_event_classes.find(params[:class_id])
      new_status = event_class.status == 'inactive' ? 'active' : 'inactive'
      event_class.update!(status: new_status)
      render json: serialize_class(event_class)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_class
      ensure_organisation_admin!(@event.organisation)
      event_class = @event.des_event_classes.find(params[:class_id])
      active_bookings = DesEventBookingClass.joins(:booking)
        .where(event_class_id: event_class.id, des_event_booking_classes: { status: 'confirmed' })
        .where(des_event_bookings: { status: ['confirmed', 'pending'] })
        .count
      if active_bookings > 0
        return render json: { error: "Cannot delete - this class has #{active_bookings} active booking(s). Cancel all bookings first." }, status: :unprocessable_entity
      end
      event_class.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end


    def cancel_entrant
      ensure_organisation_admin!(@event.organisation)
      booking = DesEventBooking.find(params[:booking_id])
      booking_class = booking.booking_classes.find(params[:booking_class_id])
      raise "Booking does not belong to this event" unless booking.event_id == @event.id

      service = DesBookingService.new(current_user, @event)
      service.admin_cancel_booking_class(booking, booking_class, current_user)
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end


    def delete_booking
      ensure_organisation_admin!(@event.organisation)
      raise Discourse::InvalidAccess unless current_user.admin?
      booking = DesEventBooking.find(params[:booking_id])
      raise "Booking does not belong to this event" unless booking.event_id == @event.id
      booking.booking_classes.destroy_all
      booking.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def change_entrant_car
      ensure_organisation_admin!(@event.organisation)
      booking = DesEventBooking.find(params[:booking_id])
      raise "Booking does not belong to this event" unless booking.event_id == @event.id
      bc = booking.booking_classes.find(params[:class_id])
      car = DesUserCar.find(params[:car_id])
      bc.update!(car_id: car.id, transponder_number: car.transponder_number)
      render json: {
        success: true,
        transponder: car.transponder_number,
        manufacturer_name: car.manufacturer&.name,
        model_name: car.car_model&.name || car.custom_model_name
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def move_entrant_class
      ensure_organisation_admin!(@event.organisation)
      booking = DesEventBooking.find(params[:booking_id])
      raise "Booking does not belong to this event" unless booking.event_id == @event.id

      from_class = DesEventClass.find(params[:from_class_id])
      to_class = DesEventClass.find(params[:to_class_id])
      raise "Target class does not belong to this event" unless to_class.event_id == @event.id
      raise "Target class is inactive" if to_class.status == 'inactive'
      raise "Target class is full" if to_class.sold_out?

      bc = booking.booking_classes.find_by!(event_class_id: from_class.id)
      bc.update!(event_class_id: to_class.id)

      from_class.update_status!
      to_class.update_status!

      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end


    def sync_transponders
      ensure_organisation_admin!(@event.organisation)
      updated = 0
      booking_classes = DesEventBookingClass.joins(:booking)
        .where(des_event_booking_classes: { status: 'confirmed' })
        .where(des_event_bookings: { event_id: @event.id, status: ['confirmed', 'pending'] })
        .where.not(car_id: nil)
        .includes(:user_car)

      booking_classes.each do |bc|
        car = bc.user_car
        next unless car
        next if car.transponder_number == bc.transponder_number
        bc.update_columns(transponder_number: car.transponder_number)
        updated += 1
      end

      render json: { success: true, updated: updated, message: "Updated #{updated} transponder number(s)" }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def remove_from_waitlist
      ensure_organisation_admin!(@event.organisation)
      entry = DesEventWaitlist.find(params[:waitlist_id])
      raise "Entry does not belong to this event" unless entry.event_id == @event.id
      entry.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end




    private

    def set_event
      @event = DesEvent.find(params[:id])
    end

    def event_params
      params.require(:event).permit(
        :title, :description, :organisation_id, :event_type_id,
        :title, :description, :organisation_id, :event_type_id,
        :start_date, :end_date, :location, :google_maps_url,
        :capacity, :refund_cutoff_days, :category_id, :booking_closing_date,
        :booking_opens_days_before, :booking_closes_days_before,
        :booking_type, :external_booking_url, :external_booking_details,
        :max_classes_per_booking, :venue_id, :rc_results_meeting_id
      )
    end

    def ensure_organisation_admin!(organisation)
      member = DesOrganisationMember
        .joins(:position)
        .where(organisation_id: organisation.id, user_id: current_user.id, status: 'active')
        .where(des_positions: { is_admin: true })
        .exists?
      raise Discourse::InvalidAccess unless member || current_user.admin?
    end

    def serialize_event(event)
      {
        id: event.id,
        title: event.title,
        description: event.description,
        description_cooked: PrettyText.cook(event.description.to_s),
        organisation: { id: event.organisation.id, name: event.organisation.name, logo_url: event.organisation.logo_url },
        event_type_id: event.event_type_id,
        event_type: event.event_type ? { id: event.event_type.id, name: event.event_type.name } : nil,
        venue_id: event.venue_id,
        venue: event.venue ? {
          id: event.venue.id, name: event.venue.name, address: event.venue.address,
          google_maps_url: event.venue.google_maps_url, website: event.venue.website,
          track_category: event.venue.track_category, track_surface: event.venue.track_surface,
          track_environment: event.venue.track_environment,
          has_portaloos: event.venue.has_portaloos, has_permanent_toilets: event.venue.has_permanent_toilets,
          has_bar: event.venue.has_bar, has_showers: event.venue.has_showers,
          has_power_supply: event.venue.has_power_supply, has_water_supply: event.venue.has_water_supply,
          has_camping: event.venue.has_camping, is_shared: event.venue.is_shared,
          parking_info: event.venue.parking_info, description: event.venue.description,
          local_facilities: event.venue.local_facilities, access_notes: event.venue.access_notes
        } : nil,
        start_date: event.start_date,
        end_date: event.end_date,
        booking_closing_date: event.booking_closing_date,
        formatted_booking_closing_date: event.booking_closing_date&.strftime('%A, %d %B %Y at %H:%M'),
        booking_opens_days_before: event.booking_opens_days_before,
        booking_closes_days_before: event.booking_closes_days_before,
        booking_manually_closed: event.booking_manually_closed,
        booking_manually_open: event.booking_manually_open,
        booking_opens_at: event.booking_opens_at,
        booking_closes_at: event.booking_closes_at,
        booking_open: event.booking_open?,
        user_has_booking_alert: current_user ? DesEventBookingAlert.exists?(user_id: current_user.id, event_id: event.id) : false,
        location: event.location,
        google_maps_url: event.google_maps_url,
        capacity: event.capacity,
        status: event.status,
        topic_url: event.topic ? "/t/#{event.topic.slug}/#{event.topic.id}" : nil,
        topic_id: event.topic_id,
        topic_slug: event.topic&.slug,
        classes: event.des_event_classes.includes(:class_type).map do |ec|
          {
            id: ec.id,
            name: ec.class_type&.name || ec.name,
            capacity: ec.capacity,
            status: ec.status,
            spaces_remaining: ec.spaces_remaining,
            waitlist_count: DesEventWaitlist.where(event_class_id: ec.id, status: 'waiting').count,
            user_waitlist_position: current_user.present? ? DesEventWaitlist.find_by(event_class_id: ec.id, user_id: current_user.id, status: 'waiting')&.position : nil
          }
        end,
        pricing: event.des_event_pricing_rule ? {
          rule_type: event.des_event_pricing_rule.rule_type,
          flat_price: event.des_event_pricing_rule.flat_price,
          first_class_price: event.des_event_pricing_rule.first_class_price,
          subsequent_class_price: event.des_event_pricing_rule.subsequent_class_price,
          member_first_class_discount: event.des_event_pricing_rule.member_first_class_discount,
          member_subsequent_discount: event.des_event_pricing_rule.member_subsequent_discount,
          junior_first_class_discount: event.des_event_pricing_rule.junior_first_class_discount,
          junior_subsequent_discount: event.des_event_pricing_rule.junior_subsequent_discount
        } : nil,
        max_classes_per_booking: event.max_classes_per_booking,
        rc_results_meeting_id: event.rc_results_meeting_id,
        is_admin: current_user.present? && is_event_admin?(event),
        user_is_member: current_user.present? && DesOrganisationMembership.where(user_id: current_user.id, organisation_id: event.organisation_id).active.exists?,
        user_is_junior: current_user.present? && begin
          dob_str = UserCustomField.find_by(user_id: current_user.id, name: 'des_date_of_birth')&.value.presence
          dob = dob_str ? Date.parse(dob_str) : current_user.date_of_birth
          if dob.present?
            age = event.start_date.year - dob.year
            age -= 1 if event.start_date < dob + age.years
            age < 16
          else
            false
          end
        end,
        refund_cutoff_days: event.refund_cutoff_days,
        refund_cutoff_date: event.refund_cutoff_days.present? && event.start_date.present? ? (event.start_date - event.refund_cutoff_days.days).strftime('%A, %d %B %Y') : nil,
        formatted_date: event.start_date&.strftime('%A, %d %B %Y at %H:%M'),
        family_members: current_user.present? ? family_members_for(event) : []
      }
    end

    def family_members_for(event)
      members = {}

      # From organisation membership family members
      membership = DesOrganisationMembership
        .where(user_id: current_user.id, organisation_id: event.organisation_id)
        .active
        .includes(family_members: :user)
        .first
      if membership
        membership.family_members.each do |fm|
          members[fm.user_id] = { user_id: fm.user_id, username: fm.user.username, is_junior: user_is_junior?(fm.user, event) }
        end
      end

      # From guardian relationship (users I am guardian of)
      DesRacingFamilyMember.for_guardian(current_user.id).includes(:user).each do |rfm|
        members[rfm.user_id] ||= {
          user_id: rfm.user_id,
          username: rfm.user.username,
          is_junior: user_is_junior?(rfm.user, event)
        }
      end

      members.values
    end

    def user_is_junior?(user, event)
      dob_str = UserCustomField.find_by(user_id: user.id, name: 'des_date_of_birth')&.value.presence
      dob = dob_str ? Date.parse(dob_str) : user.date_of_birth
      return false unless dob.present?
      age = event.start_date.year - dob.year
      age -= 1 if event.start_date < dob + age.years
      age < 16
    end

    def is_event_admin?(event)
      return true if current_user.admin?
      DesOrganisationMember.joins(:position)
        .where(organisation_id: event.organisation_id, user_id: current_user.id)
        .where(des_positions: { is_admin: true })
        .exists?
    end

    def serialize_class(event_class)
      {
        id: event_class.id,
        name: event_class.class_type&.name || event_class.name,
        capacity: event_class.capacity,
        status: event_class.status,
        spaces_remaining: event_class.spaces_remaining
      }
    end

    def serialize_events(events)
      events.map { |e| serialize_event(e) }
    end

    def geocode_postcode(postcode)
      return nil if postcode.blank?
      clean = postcode.to_s.strip.gsub(/\s+/, '').upcase
      response = Net::HTTP.get(URI("https://api.postcodes.io/postcodes/#{clean}"))
      data = JSON.parse(response)
      return nil unless data['status'] == 200
      { lat: data['result']['latitude'], lng: data['result']['longitude'] }
    rescue
      nil
    end

    def distance_in_miles(lat1, lng1, lat2, lng2)
      rad_per_deg = Math::PI / 180
      earth_radius_miles = 3958.8
      dlat = (lat2 - lat1) * rad_per_deg
      dlng = (lng2 - lng1) * rad_per_deg
      a = Math.sin(dlat / 2)**2 + Math.cos(lat1 * rad_per_deg) * Math.cos(lat2 * rad_per_deg) * Math.sin(dlng / 2)**2
      2 * earth_radius_miles * Math.asin(Math.sqrt(a))
    end

    def filter_by_distance(topics, postcode, max_miles)
      return topics if postcode.blank? || max_miles.blank?
      max_miles = max_miles.to_f
      return topics if max_miles <= 0
      user_coords = geocode_postcode(postcode)
      return topics unless user_coords

      venue_cache = {}
      topics.select do |topic|
        next true unless topic[:venue_postcode].present?
        venue_id = topic[:venue_id]
        unless venue_cache.key?(venue_id)
          venue_cache[venue_id] = geocode_postcode(topic[:venue_postcode])
        end
        venue_coords = venue_cache[venue_id]
        next true unless venue_coords
        distance_in_miles(user_coords[:lat], user_coords[:lng], venue_coords[:lat], venue_coords[:lng]) <= max_miles
      end
    end

    def apply_venue_filters(events, params)
      return events unless params[:track_environment].present? || params[:track_surface].present?

      venue_ids = DesVenue.all
      venue_ids = venue_ids.where(track_environment: params[:track_environment]) if params[:track_environment].present?
      venue_ids = venue_ids.where(track_surface: params[:track_surface]) if params[:track_surface].present?

      events.where(venue_id: venue_ids.pluck(:id))
    end

    def apply_scale_power_filters(topics, params)
      if params[:scale].present?
        topics = topics.select { |t| t[:scale] == params[:scale] }
      end
      if params[:power_type].present?
        topics = topics.select do |t|
          next true if t[:power_type].blank?
          if params[:power_type] == 'mixed'
            %w[electric nitro mixed].include?(t[:power_type])
          else
            t[:power_type] == params[:power_type] || t[:power_type] == 'mixed'
          end
        end
      end
      topics
    end

    def rc_filter_options
      {
        organisations: DesOrganisation.approved.order(:name).map { |o| { id: o.id, name: o.name } },
        event_types: DesEventType.order(:name).map { |et| { id: et.id, name: et.name } },
        track_environments: ['outdoor', 'indoor_covered'],
        track_surfaces: DesVenue.distinct.pluck(:track_surface).compact.sort
      }
    end

    def serialize_rc_topic(event)
      first_class_type = event.des_event_classes.first&.class_type
      {
        id: event.id,
        type: 'native',
        topic_id: event.topic_id,
        title: event.title,
        start_date: event.start_date,
        end_date: event.end_date,
        formatted_date: event.start_date&.strftime('%a %d %b %Y at %H:%M'),
        status: event.status,
        booking_open: event.booking_open?,
        booking_opens_at: event.booking_opens_at,
        booking_closes_at: event.booking_closes_at,
        booking_manually_closed: event.booking_manually_closed,
        user_has_booking_alert: current_user ? DesEventBookingAlert.exists?(user_id: current_user.id, event_id: event.id) : false,
        organisation: event.organisation ? {
          id: event.organisation.id,
          name: event.organisation.name,
          logo_url: event.organisation.logo_url
        } : nil,
        venue: event.venue ? {
          name: event.venue.name,
          postcode: event.venue.postcode,
          track_environment: event.venue.track_environment,
          track_surface: event.venue.track_surface,
          track_category: event.venue.track_category,
          track_type: event.venue.track_type,
          has_permanent_toilets: event.venue.has_permanent_toilets,
          has_portaloos: event.venue.has_portaloos,
          has_cafe: event.venue.has_cafe,
          has_bar: event.venue.has_bar,
          has_showers: event.venue.has_showers,
          has_power_supply: event.venue.has_power_supply,
          has_water_supply: event.venue.has_water_supply,
          has_camping: event.venue.has_camping,
          is_shared: event.venue.is_shared
        } : nil,
        venue_id: event.venue_id,
        venue_postcode: event.venue&.postcode,
        distance_miles: nil,
        classes: event.des_event_classes.map(&:name),
        scale: first_class_type&.scale,
        power_type: first_class_type&.power_type,
        is_today: event.start_date&.to_date == Date.today,
        is_past: event.start_date ? event.start_date < Time.now : false,
        topic_url: event.topic_id ? "/t/#{event.topic_id}" : nil
      }
    end

    def serialize_imported_event(event)
      {
        id: event.id,
        type: 'imported',
        title: event.title,
        discipline: event.discipline,
        series_type: event.series_type,
        region: event.region,
        round_number: event.round_number,
        classes_raw: event.classes_raw_array,
        scale: event.scale,
        power_type: event.power_type,
        surface: event.surface,
        start_date: event.starts_at&.iso8601,
        end_date: event.ends_at&.iso8601,
        formatted_date: event.starts_at&.strftime('%a %d %b %Y at %H:%M'),
        booking_url: event.booking_url,
        is_today: event.starts_at&.to_date == Date.today,
        is_past: event.starts_at ? event.starts_at < Time.now : false,
        venue: event.venue ? {
          id: event.venue.id,
          name: event.venue.name,
          postcode: event.venue.postcode,
          latitude: event.venue.latitude,
          longitude: event.venue.longitude,
          track_surface: event.venue.track_surface,
          track_environment: event.venue.track_environment
        } : nil,
        venue_postcode: event.venue&.postcode,
        organisation: event.organisation ? {
          id: event.organisation.id,
          name: event.organisation.name
        } : { id: nil, name: 'BRCA' },
        organisation_id: event.organisation_id
      }
    end

    def fetch_imported_events(params)
      imported = DesImportedEvent.includes(:venue, :organisation)

      case params[:time_filter]
      when 'past'
        imported = imported.where('starts_at >= ? AND starts_at < ?', 30.days.ago, Time.now.beginning_of_day).order(starts_at: :desc)
      when 'today'
        imported = imported.where('starts_at >= ? AND starts_at < ?', Time.now.beginning_of_day, Time.now.end_of_day).order(starts_at: :asc)
      when 'upcoming'
        imported = imported.where('starts_at > ?', Time.now.end_of_day).order(starts_at: :asc)
      when 'all'
        imported = imported.where('starts_at >= ?', 30.days.ago).order(starts_at: :asc)
      else
        imported = imported.where('starts_at >= ?', Time.now.beginning_of_day).order(starts_at: :asc)
      end

      if params[:scale].present?
        imported = imported.where(scale: params[:scale])
      end
      if params[:power_type].present?
        if params[:power_type] == 'mixed'
          imported = imported.where(power_type: %w[electric nitro mixed])
        else
          imported = imported.where(power_type: [params[:power_type], 'mixed'])
        end
      end

      if params[:organisation_id].present?
        imported = imported.where(organisation_id: params[:organisation_id].to_i)
      end

      if params[:postcode].present? && params[:max_distance_miles].present?
        user_coords = geocode_postcode(params[:postcode])
        if user_coords
          max_miles = params[:max_distance_miles].to_f
          imported = imported.to_a.select do |event|
            next true if event.venue.nil?
            next true if event.venue.latitude.blank? || event.venue.longitude.blank?
            distance_in_miles(
              user_coords[:lat], user_coords[:lng],
              event.venue.latitude.to_f, event.venue.longitude.to_f
            ) <= max_miles
          end
        end
      end

      imported.map { |e| serialize_imported_event(e) }
    end

  end
end
