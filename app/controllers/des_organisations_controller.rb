# frozen_string_literal: true

class DesOrganisationsController < ApplicationController
  before_action :ensure_logged_in
  before_action :set_organisation, only: [:show, :update, :approve, :reject, :members]

  def index
    organisations = if current_user.admin?
      DesOrganisation.all.order(:name)
    else
      DesOrganisation.approved.order(:name)
    end
    render json: serialize_organisations(organisations)
  end

  def show
    render json: serialize_organisation(@organisation)
  end

  def create
    organisation = DesOrganisation.new(organisation_params)
    organisation.created_by = current_user.id
    organisation.status = 'pending'

    if organisation.save
      render json: serialize_organisation(organisation), status: :created
    else
      render json: { errors: organisation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    ensure_organisation_admin!
    if @organisation.update(organisation_params)
      render json: serialize_organisation(@organisation)
    else
      render json: { errors: @organisation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def approve
    ensure_admin!
    @organisation.approve!(params[:surcharge_percentage].to_f)
    render json: serialize_organisation(@organisation)
  end

  def reject
    ensure_admin!
    @organisation.reject!(params[:reason])
    render json: serialize_organisation(@organisation)
  end

  def members
    ensure_organisation_admin!
    members = @organisation.des_organisation_members.active.includes(:user, :position)
    render json: serialize_members(members)
  end

  def add_member
    ensure_organisation_admin!
    member = DesOrganisationMember.create!(
      organisation_id: @organisation.id,
      user_id: params[:user_id],
      position_id: params[:position_id],
      status: 'active'
    )
    render json: serialize_member(member), status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
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
    member = DesOrganisationMember
      .joins(:position)
      .where(organisation_id: @organisation.id, user_id: current_user.id, status: 'active')
      .where(des_positions: { is_admin: true })
      .exists?
    raise Discourse::InvalidAccess unless member || current_user.admin?
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

  def serialize_organisations(organisations)
    organisations.map { |o| serialize_organisation(o) }
  end

  def serialize_member(member)
    {
      id: member.id,
      user: {
        id: member.user.id,
        username: member.user.username
      },
      position: {
        id: member.position.id,
        name: member.position.name,
        is_admin: member.position.is_admin
      },
      status: member.status
    }
  end

  def serialize_members(members)
    members.map { |m| serialize_member(m) }
  end
end
