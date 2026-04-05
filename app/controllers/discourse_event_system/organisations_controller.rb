# frozen_string_literal: true

module DiscourseEventSystem
  class OrganisationsController < ApplicationController
    before_action :ensure_logged_in
    before_action :set_organisation, only: [:show, :update, :approve, :reject, :members, :add_member, :remove_member, :rules, :create_rule, :destroy_rule, :class_types, :create_class_type, :destroy_class_type, :create_class_type_rule, :destroy_class_type_rule, :membership_types, :create_membership_type, :update_membership_type, :destroy_membership_type, :join, :confirm_membership]

    def index
      organisations = current_user.admin? ? DesOrganisation.all.order(:name) : DesOrganisation.approved.order(:name)
      render json: { organisations: serialize_organisations(organisations) }
    end

    def show
      render json: serialize_organisation_detail(@organisation)
    end

    def create
      organisation = DesOrganisation.new(organisation_params)
      organisation.created_by = current_user.id
      organisation.status = 'pending'
      if organisation.save
        render json: { organisation: serialize_organisation(organisation) }, status: :created
      else
        render json: { errors: organisation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      ensure_organisation_admin!
      if @organisation.update(organisation_params)
        render json: { organisation: serialize_organisation(@organisation) }
      else
        render json: { errors: @organisation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def approve
      ensure_admin!
      @organisation.approve!(params[:surcharge_percentage].to_f)
      render json: { success: true }
    end

    def reject
      ensure_admin!
      @organisation.reject!(params[:reason])
      render json: { success: true }
    end

    def members
      members = @organisation.des_organisation_members.active.includes(:user, :position)
      render json: { members: serialize_members(members) }
    end

    def add_member
      ensure_organisation_admin!
      user = User.find_by_username(params[:username])
      return render json: { error: 'User not found' }, status: :not_found unless user

      member = DesOrganisationMember.find_or_initialize_by(
        organisation_id: @organisation.id,
        user_id: user.id
      )
      member.position_id = params[:position_id]
      member.status = 'active'

      if member.save
        render json: { member: serialize_member(member.reload) }, status: :created
      else
        render json: { errors: member.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def remove_member
      ensure_organisation_admin!
      member = DesOrganisationMember.find_by(
        id: params[:member_id],
        organisation_id: @organisation.id
      )
      return render json: { error: 'Member not found' }, status: :not_found unless member
      member.update!(status: 'inactive')
      render json: { success: true }
    end


    def class_types
      ensure_organisation_admin!
      global = DesEventClassType.global
      org_types = DesEventClassType.for_organisation(@organisation.id).includes(:compatibility_rules)
      manufacturers = DesManufacturer.all.order(:name)
      render json: {
        global_class_types: global.map { |ct| serialize_class_type(ct) },
        org_class_types: org_types.map { |ct| serialize_class_type_with_rules(ct) },
        manufacturers: manufacturers.map { |m| { id: m.id, name: m.name, status: m.status } },
        drivelines: DesCarModel::DRIVELINES,
        chassis_types: DesCarModel::CHASSIS_TYPES
      }
    end

    def create_class_type
      ensure_organisation_admin!
      ct = DesEventClassType.create!(
        name: params[:name],
        description: params[:description],
        organisation_id: @organisation.id
      )
      render json: serialize_class_type_with_rules(ct), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_class_type
      ensure_organisation_admin!
      ct = DesEventClassType.find_by(id: params[:class_type_id], organisation_id: @organisation.id)
      return render json: { error: 'Not found' }, status: :not_found unless ct
      ct.destroy
      render json: { success: true }
    end

    def create_class_type_rule
      ensure_organisation_admin!
      ct = DesEventClassType.find_by(id: params[:class_type_id], organisation_id: @organisation.id)
      return render json: { error: 'Not found' }, status: :not_found unless ct
      rule = DesClassCompatibilityRule.create!(
        class_type_id: ct.id,
        rule_type: params[:rule_type],
        rule_value: params[:rule_value],
        organisation_id: @organisation.id
      )
      render json: serialize_rule(rule), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_class_type_rule
      ensure_organisation_admin!
      rule = DesClassCompatibilityRule.find_by(id: params[:rule_id], organisation_id: @organisation.id)
      return render json: { error: 'Not found' }, status: :not_found unless rule
      rule.destroy
      render json: { success: true }
    end

    def rules
      ensure_organisation_admin!
      rules = DesClassCompatibilityRule.for_organisation(@organisation.id).includes(:class_type)
      class_types = DesEventClassType.all
      render json: {
        rules: rules.map { |r| serialize_rule(r) },
        class_types: class_types.map { |ct| { id: ct.id, name: ct.name } }
      }
    end

    def create_rule
      ensure_organisation_admin!
      rule = DesClassCompatibilityRule.create!(
        class_type_id: params[:class_type_id],
        rule_type: params[:rule_type],
        rule_value: params[:rule_value],
        organisation_id: @organisation.id
      )
      render json: serialize_rule(rule), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_rule
      ensure_organisation_admin!
      rule = DesClassCompatibilityRule.find_by(id: params[:rule_id], organisation_id: @organisation.id)
      return render json: { error: 'Not found' }, status: :not_found unless rule
      rule.destroy
      render json: { success: true }
    end

    def serialize_membership_type(type)
      {
        id: type.id,
        name: type.name,
        description: type.description,
        price: type.price,
        duration_months: type.duration_months,
        discount_percentage: type.discount_percentage,
        max_members: type.max_members,
        is_family: type.is_family,
        active: type.active
      }
    end

    def serialize_class_type(ct)
      {
        id: ct.id,
        name: ct.name,
        description: ct.description,
        organisation_id: ct.organisation_id
      }
    end

    def serialize_class_type_with_rules(ct)
      serialize_class_type(ct).merge(
        rules: ct.compatibility_rules.map { |r| serialize_rule(r) }
      )
    end

    def membership_types
      types = @organisation.des_organisation_membership_types.active
      render json: {
        membership_types: types.map { |t| serialize_membership_type(t) },
        is_admin: is_org_admin?
      }
    end

    def create_membership_type
      ensure_organisation_admin!
      type = @organisation.des_organisation_membership_types.create!(
        name: params[:name],
        description: params[:description],
        price: params[:price],
        duration_months: params[:duration_months],
        discount_percentage: params[:discount_percentage] || 0,
        max_members: params[:max_members] || 1,
        is_family: params[:is_family] || false,
        active: true
      )
      render json: serialize_membership_type(type), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_membership_type
      ensure_organisation_admin!
      type = @organisation.des_organisation_membership_types.find(params[:type_id])
      type.update!(
        name: params[:name],
        description: params[:description],
        price: params[:price],
        duration_months: params[:duration_months],
        discount_percentage: params[:discount_percentage] || 0,
        active: params[:active]
      )
      render json: serialize_membership_type(type)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy_membership_type
      ensure_organisation_admin!
      type = @organisation.des_organisation_membership_types.find(params[:type_id])
      type.update!(active: false)
      render json: { success: true }
    end

    def join
      type = @organisation.des_organisation_membership_types.find(params[:membership_type_id])
      membership = DesOrganisationMembership.create!(
        organisation_id: @organisation.id,
        user_id: current_user.id,
        membership_type_id: type.id,
        status: 'pending',
        starts_at: Time.now,
        expires_at: Time.now + type.duration_months.months
      )
      if type.free?
        membership.activate!(nil, 0)
        render json: { success: true, membership_id: membership.id, free: true }
      else
        paypal = DesPaypalService.new
        response = paypal.create_membership_order(membership, type)
        order_id = response['id']
        approval_url = response['links'].find { |l| l['rel'] == 'approve' }['href']
        membership.update!(paypal_order_id: order_id)
        render json: { approval_url: approval_url, membership_id: membership.id }
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def add_family_member
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless membership
      new_user = User.find_by(username: params[:username])
      return render json: { error: 'User not found' }, status: :not_found unless new_user
      membership.add_family_member!(new_user)
      render json: { success: true, user: { id: new_user.id, username: new_user.username } }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def remove_family_member
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless membership
      member_user = User.find(params[:user_id])
      membership.remove_family_member!(member_user)
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def confirm_membership
      membership = DesOrganisationMembership.find_by(
        id: params[:membership_id],
        user_id: current_user.id
      )
      return render json: { error: 'Not found' }, status: :not_found unless membership
      paypal = DesPaypalService.new
      capture = paypal.capture_order(membership.paypal_order_id)
      capture_id = capture.dig('purchase_units', 0, 'payments', 'captures', 0, 'id')
      amount = capture.dig('purchase_units', 0, 'payments', 'captures', 0, 'amount', 'value')
      membership.activate!(capture_id, amount)
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def my_memberships
      memberships = DesOrganisationMembership
        .where(user_id: current_user.id)
        .includes(:organisation, :membership_type)
        .order(expires_at: :desc)
      render json: {
        memberships: memberships.map { |m|
          {
            id: m.id,
            organisation: { id: m.organisation.id, name: m.organisation.name },
            membership_type: { name: m.membership_type.name, price: m.membership_type.price },
            status: m.status,
            starts_at: m.starts_at,
            expires_at: m.expires_at,
            amount_paid: m.amount_paid
          }
        }
      }
    end

    def create_discourse_group!(organisation)
      return if organisation.discourse_group_id.present?
      group_name = organisation.name.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
      group_name = "org_#{group_name}"
      group = Group.find_by(name: group_name)
      unless group
        group = Group.create!(
          name: group_name,
          full_name: organisation.name,
          bio_raw: "Members of #{organisation.name}",
          visibility_level: Group.visibility_levels[:members],
          members_visibility_level: Group.visibility_levels[:members]
        )
      end
      organisation.update!(discourse_group_id: group.id)
    rescue => e
      Rails.logger.error "Failed to create Discourse group for org #{organisation.id}: \#{e.message}"
    end

    private

    def set_organisation
      @organisation = DesOrganisation.find(params[:id])
    end

    def organisation_params
      params.require(:organisation).permit(
        :name, :description, :email, :phone,
        :website, :address, :logo_url, :google_maps_url, :paypal_email
      )
    end

    def ensure_admin!
      raise Discourse::InvalidAccess unless current_user.admin?
    end

    def ensure_organisation_admin!
      is_admin = DesOrganisationMember
        .joins(:position)
        .where(organisation_id: @organisation.id, user_id: current_user.id, status: 'active')
        .where(des_positions: { is_admin: true })
        .exists?
      raise Discourse::InvalidAccess unless is_admin || current_user.admin?
    end

    def is_org_admin?
      DesOrganisationMember
        .joins(:position)
        .where(organisation_id: @organisation.id, user_id: current_user.id, status: 'active')
        .where(des_positions: { is_admin: true })
        .exists? || current_user.admin?
    end

    def serialize_organisation_detail(org)
      members = org.des_organisation_members.active.includes(:user, :position)
      events = DesEvent.where(organisation_id: org.id).order(start_date: :desc).limit(10)

      {
        id: org.id,
        name: org.name,
        description: org.description,
        email: org.email,
        phone: org.phone,
        website: org.website,
        address: org.address,
        logo_url: org.logo_url,
        google_maps_url: org.google_maps_url,
        status: org.status,
        surcharge_percentage: org.surcharge_percentage,
        rejection_reason: org.rejection_reason,
        created_by: org.creator&.username,
        is_admin: is_org_admin?,
        members: serialize_members(members),
        events: events.map { |e|
          {
            id: e.id,
            title: e.title,
            start_date: e.start_date,
            booking_closing_date: e.booking_closing_date,
            location: e.location,
            status: e.status,
            booking_type: e.booking_type,
            classes: e.des_event_classes.map { |c|
              {
                id: c.id,
                name: c.name,
                capacity: c.capacity,
                spaces_remaining: c.spaces_remaining,
                status: c.status,
                bookings_count: c.capacity - c.spaces_remaining
              }
            }
          }
        },
        positions: DesPosition.all.map { |p| { id: p.id, name: p.name, is_admin: p.is_admin } }
      }
    end

    def serialize_organisation(org)
      {
        id: org.id,
        name: org.name,
        description: org.description,
        email: org.email,
        phone: org.phone,
        website: org.website,
        address: org.address,
        logo_url: org.logo_url,
        google_maps_url: org.google_maps_url,
        status: org.status,
        surcharge_percentage: org.surcharge_percentage,
        rejection_reason: org.rejection_reason,
        created_by: org.creator&.username
      }
    end

    def serialize_organisations(orgs)
      orgs.map { |o| serialize_organisation(o) }
    end

    def serialize_member(member)
      {
        id: member.id,
        user: { id: member.user.id, username: member.user.username },
        position: { id: member.position_id, name: member.position&.name, is_admin: member.position&.is_admin },
        status: member.status
      }
    end

    def serialize_rule(rule)
      {
        id: rule.id,
        class_type_id: rule.class_type_id,
        class_type_name: rule.class_type&.name,
        rule_type: rule.rule_type,
        rule_value: rule.rule_value,
        organisation_id: rule.organisation_id
      }
    end

    def serialize_members(members)
      members.map { |m| serialize_member(m) }
    end
  end
end
