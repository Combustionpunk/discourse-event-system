# frozen_string_literal: true

module DiscourseEventSystem
  class OrganisationsController < ApplicationController
    before_action :ensure_logged_in
    before_action :set_organisation, only: [:show, :update, :approve, :reject, :members, :add_member, :remove_member, :rules, :create_rule, :destroy_rule, :class_types, :create_class_type, :destroy_class_type, :create_class_type_rule, :destroy_class_type_rule, :membership_types, :create_membership_type, :update_membership_type, :destroy_membership_type, :join, :confirm_membership, :admin_memberships, :admin_add_membership, :admin_update_membership, :admin_add_family_member, :admin_remove_family_member, :admin_update_family_member]

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

    def admin_memberships
      ensure_organisation_admin!
      memberships = DesOrganisationMembership.where(organisation_id: @organisation.id)
        .includes(:user, :membership_type, family_members: :user)
        .order(created_at: :desc)
      render json: { memberships: memberships.map { |m|
        {
          id: m.id,
          username: m.user&.username,
          membership_type: m.membership_type&.name,
          membership_type_id: m.membership_type_id,
          is_family: m.membership_type&.is_family || false,
          max_members: m.membership_type&.max_members || 1,
          status: m.status,
          starts_at: m.starts_at,
          expires_at: m.expires_at,
          family_members: m.family_members.map { |fm|
            {
              user_id: fm.user_id,
              username: fm.user&.username,
              date_of_birth: fm.user&.date_of_birth&.strftime('%Y-%m-%d')
            }
          }
        }
      }}
    end

    def admin_add_membership
      ensure_organisation_admin!
      user = User.find_by(username: params[:username])
      raise Discourse::InvalidParameters, "User not found" unless user
      type = @organisation.des_organisation_membership_types.find(params[:membership_type_id])
      expires_at = params[:expires_at].present? ? Date.parse(params[:expires_at]) : Date.today + type.duration_months.months
      membership = DesOrganisationMembership.create!(
        user_id: user.id,
        organisation_id: @organisation.id,
        membership_type_id: type.id,
        status: 'active',
        starts_at: Date.today,
        expires_at: expires_at,
        amount_paid: params[:amount_paid].presence || 0
      )

      # Add family members if this is a family membership
      if type.is_family && params[:family_usernames].present?
        usernames = params[:family_usernames].values.map(&:strip).reject(&:blank?)
        usernames.each do |username|
          family_user = User.find_by(username: username)
          raise Discourse::InvalidParameters, "Family member '#{username}' not found" unless family_user
          membership.add_family_member!(family_user)
        end
      end

      render json: { success: true, membership_id: membership.id }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def admin_update_membership
      ensure_organisation_admin!
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], organisation_id: @organisation.id)
      raise Discourse::InvalidAccess unless membership
      membership.update!(
        status: params[:status] || membership.status,
        expires_at: params[:expires_at].present? ? Date.parse(params[:expires_at]) : membership.expires_at
      )
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def admin_add_family_member
      ensure_organisation_admin!
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], organisation_id: @organisation.id)
      raise Discourse::InvalidAccess unless membership
      new_user = User.find_by(username: params[:username])
      return render json: { error: 'User not found' }, status: :not_found unless new_user
      new_user.update!(date_of_birth: Date.parse(params[:date_of_birth])) if params[:date_of_birth].present?
      membership.add_family_member!(new_user)
      render json: {
        success: true,
        user: {
          user_id: new_user.id,
          username: new_user.username,
          date_of_birth: new_user.date_of_birth&.strftime('%Y-%m-%d')
        }
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def admin_remove_family_member
      ensure_organisation_admin!
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], organisation_id: @organisation.id)
      raise Discourse::InvalidAccess unless membership
      member_user = User.find(params[:user_id])
      membership.remove_family_member!(member_user)
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def admin_update_family_member
      ensure_organisation_admin!
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], organisation_id: @organisation.id)
      raise Discourse::InvalidAccess unless membership
      member_user = User.find(params[:user_id])
      raise Discourse::InvalidAccess unless membership.family_members.exists?(user_id: member_user.id)
      member_user.update!(date_of_birth: Date.parse(params[:date_of_birth])) if params[:date_of_birth].present?
      render json: { success: true, date_of_birth: member_user.date_of_birth&.strftime('%Y-%m-%d') }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
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

    def confirm_membership_direct
      membership = DesOrganisationMembership.find_by(
        id: params[:membership_id],
        user_id: current_user.id
      )
      return render json: { error: 'Not found' }, status: :not_found unless membership
      return render json: { success: true, already_active: true } if membership.status == 'active'
      paypal = DesPaypalService.new
      capture = paypal.capture_order(membership.paypal_order_id)
      capture_id = capture.dig('purchase_units', 0, 'payments', 'captures', 0, 'id')
      amount = capture.dig('purchase_units', 0, 'payments', 'captures', 0, 'amount', 'value')
      membership.activate!(capture_id, amount)
      render json: { success: true, organisation: { id: membership.organisation.id, name: membership.organisation.name }, is_family: membership.membership_type&.is_family || false, max_members: membership.membership_type&.max_members || 1, membership_id: membership.id }
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

    def family_members
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless membership
      members = membership.family_members.includes(:user)
      render json: {
        membership_id: membership.id,
        is_family: membership.membership_type&.is_family || false,
        max_members: membership.membership_type&.max_members || 1,
        organisation_name: membership.organisation.name,
        family_members: members.map { |fm|
          {
            user_id: fm.user_id,
            username: fm.user&.username,
            name: fm.user&.name,
            avatar_url: fm.user&.avatar_template&.gsub('{size}', '45'),
            date_of_birth: fm.user&.custom_fields&.dig('des_date_of_birth'),
            brca_membership_number: fm.user&.custom_fields&.dig('brca_membership_number')
          }
        }
      }
    end

    def add_family_member_self
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless membership
      raise Discourse::InvalidAccess unless membership.membership_type&.is_family

      if params[:create_user].present?
        # Create a new Discourse user
        username = params[:username]&.strip
        name = params[:name]&.strip
        raise Discourse::InvalidParameters, "Username is required" if username.blank?
        raise Discourse::InvalidParameters, "Full name is required" if name.blank?

        email = params[:email].present? ? params[:email].strip : "#{username}@rcmisfits.noreply"
        password = SecureRandom.hex(8)

        user = User.new(
          username: username,
          name: name,
          email: email,
          password: password,
          active: true,
          approved: true,
          trust_level: 1
        )
        user.skip_email_validation = true if email.end_with?('@rcmisfits.noreply')

        unless user.save
          return render json: { error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end

        user.email_tokens.update_all(confirmed: true)
        user.activate

        # Set custom fields
        if params[:date_of_birth].present?
          user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
        end
        if params[:brca_membership_number].present?
          user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
        end
        user.save_custom_fields

        membership.add_family_member!(user)

        render json: {
          success: true,
          created: true,
          password: password,
          user: {
            user_id: user.id,
            username: user.username,
            name: user.name,
            avatar_url: user.avatar_template&.gsub('{size}', '45'),
            date_of_birth: user.custom_fields['des_date_of_birth'],
            brca_membership_number: user.custom_fields['brca_membership_number']
          }
        }
      else
        # Link existing user
        user = User.find_by(username: params[:username])
        return render json: { error: 'User not found' }, status: :not_found unless user

        if params[:date_of_birth].present?
          user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
        end
        if params[:brca_membership_number].present?
          user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
        end
        user.save_custom_fields if params[:date_of_birth].present? || params[:brca_membership_number].present?

        membership.add_family_member!(user)

        render json: {
          success: true,
          created: false,
          user: {
            user_id: user.id,
            username: user.username,
            name: user.name,
            avatar_url: user.avatar_template&.gsub('{size}', '45'),
            date_of_birth: user.custom_fields['des_date_of_birth'],
            brca_membership_number: user.custom_fields['brca_membership_number']
          }
        }
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def remove_family_member_self
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless membership
      member_user = User.find(params[:user_id])
      membership.remove_family_member!(member_user)
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_family_member_self
      membership = DesOrganisationMembership.find_by(id: params[:membership_id], user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless membership
      member_user = User.find(params[:user_id])
      raise Discourse::InvalidAccess unless membership.family_members.exists?(user_id: member_user.id)

      if params[:date_of_birth].present?
        member_user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
      end
      if params[:brca_membership_number].present?
        member_user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
      elsif params.key?(:brca_membership_number)
        member_user.custom_fields['brca_membership_number'] = nil
      end
      member_user.save_custom_fields

      render json: {
        success: true,
        date_of_birth: member_user.custom_fields['des_date_of_birth'],
        brca_membership_number: member_user.custom_fields['brca_membership_number']
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end


    def my_organisations
      # Orgs where user has active membership
      membership_org_ids = DesOrganisationMembership
        .where(user_id: current_user.id, status: 'active')
        .where('expires_at > ?', Time.now)
        .pluck(:organisation_id)

      # Orgs where user is a member
      member_org_ids = DesOrganisationMember
        .where(user_id: current_user.id, status: 'active')
        .pluck(:organisation_id)

      org_ids = (membership_org_ids + member_org_ids).uniq
      organisations = DesOrganisation.where(id: org_ids).order(:name)

      render json: {
        organisations: organisations.map { |o|
          membership = DesOrganisationMembership
            .where(user_id: current_user.id, organisation_id: o.id, status: 'active')
            .where('expires_at > ?', Time.now)
            .includes(:membership_type)
            .first
          positions = DesOrganisationMember
            .where(user_id: current_user.id, organisation_id: o.id, status: 'active')
            .includes(:position)
            .map { |m| m.position.name }
          {
            id: o.id,
            name: o.name,
            description: o.description,
            status: o.status,
            membership: membership ? {
              type: membership.membership_type.name,
              expires_at: membership.expires_at
            } : nil,
            positions: positions
          }
        }
      }
    end

    def my_memberships
      memberships = DesOrganisationMembership
        .where(user_id: current_user.id)
        .includes(:organisation, :membership_type, family_members: :user)
        .order(expires_at: :desc)
      render json: {
        memberships: memberships.map { |m|
          {
            id: m.id,
            organisation: { id: m.organisation.id, name: m.organisation.name },
            membership_type: { name: m.membership_type.name, price: m.membership_type.price },
            is_family: m.membership_type&.is_family || false,
            max_members: m.membership_type&.max_members || 1,
            status: m.status,
            starts_at: m.starts_at,
            expires_at: m.expires_at,
            amount_paid: m.amount_paid,
            family_members_count: m.family_members.count,
            family_members: m.family_members.map { |fm|
              {
                user_id: fm.user_id,
                username: fm.user&.username,
                name: fm.user&.name,
                avatar_url: fm.user&.avatar_template&.gsub('{size}', '45'),
                date_of_birth: fm.user&.custom_fields&.dig('des_date_of_birth'),
                brca_membership_number: fm.user&.custom_fields&.dig('brca_membership_number')
              }
            }
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
        positions: DesPosition.all.map { |p| { id: p.id, name: p.name, is_admin: p.is_admin } },
        membership_types: org.des_organisation_membership_types.active.map { |t| serialize_membership_type(t) },
        is_member: current_user.present? && DesOrganisationMembership.where(user_id: current_user.id, organisation_id: org.id).active.exists?
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
