# frozen_string_literal: true

module DiscourseEventSystem
  class TranspondersController < ApplicationController
    before_action :ensure_logged_in

    def index
      transponders = DesUserTransponder.for_user(current_user.id)
      render json: { transponders: transponders.map { |t| serialize_transponder(t) } }
    end

    def for_user
      unless current_user.admin? || current_user.id == params[:user_id].to_i || org_official?
        return render json: { error: 'Unauthorized' }, status: :forbidden
      end
      transponders = DesUserTransponder.for_user(params[:user_id])
      render json: { transponders: transponders.map { |t| serialize_transponder(t) } }
    end

    def create
      shortcode = DesUserTransponder.next_shortcode_for(current_user.id)
      transponder = DesUserTransponder.create!(
        user_id: current_user.id,
        shortcode: shortcode,
        long_code: params[:long_code].to_s.strip,
        notes: params[:notes].to_s.strip.presence
      )
      render json: serialize_transponder(transponder), status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update
      transponder = DesUserTransponder.find_by!(id: params[:id], user_id: current_user.id)
      transponder.update!(
        long_code: params[:long_code].present? ? params[:long_code].to_s.strip : transponder.long_code,
        notes: params[:notes].to_s.strip.presence
      )
      render json: serialize_transponder(transponder)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      transponder = DesUserTransponder.find_by!(id: params[:id], user_id: current_user.id)
      DesUserCar.where(user_id: current_user.id, transponder_number: transponder.long_code)
                .update_all(transponder_number: nil)
      transponder.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def org_official?
      DesOrganisationMember.exists?(user_id: current_user.id, status: 'active')
    end

    def serialize_transponder(t)
      {
        id: t.id,
        shortcode: t.shortcode,
        long_code: t.long_code,
        notes: t.notes,
        display_name: t.display_name
      }
    end
  end
end
