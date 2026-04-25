# frozen_string_literal: true

module DiscourseEventSystem
  class EventsController < ApplicationController
    before_action :ensure_logged_in, except: [:index, :show, :public_entrants]
    before_action :set_event, only: [:show, :update, :update_pricing, :publish, :cancel, :entrants, :public_entrants, :export_csv, :add_class, :update_class, :toggle_class_status, :cancel_entrant, :delete_booking, :change_entrant_car, :move_entrant_class, :sync_transponders, :destroy_class, :remove_from_waitlist]

    def index
      events = DesEvent.published.includes(:organisation, :event_type, :des_event_classes, :venue)

      # Filter by time
      case params[:filter]
      when 'past'
        events = events.where('start_date < ?', Time.now).order(start_date: :desc)
      else
        events = events.upcoming.order(start_date: :asc)
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
        class_types: DesEventClassType.all.order(:name).map { |ct| { id: ct.id, name: ct.name } }
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
            elsif is_member
              '2'
            else
              '3'
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
        :booking_type, :external_booking_url, :external_booking_details,
        :max_classes_per_booking, :venue_id
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

  end
end
