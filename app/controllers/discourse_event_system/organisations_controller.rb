# frozen_string_literal: true

module DiscourseEventSystem
  class OrganisationsController < ApplicationController
    before_action :ensure_logged_in
    before_action :set_organisation, only: [:show, :update, :approve, :reject, :members, :add_member, :remove_member]

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
            status: e.status
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

    def serialize_members(members)
      members.map { |m| serialize_member(m) }
    end
  end
end
