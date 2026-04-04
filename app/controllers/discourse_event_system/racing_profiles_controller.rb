# frozen_string_literal: true

module DiscourseEventSystem
  class RacingProfilesController < ApplicationController
    before_action :ensure_logged_in

    def show
      render json: {
        user: {
          id: current_user.id,
          username: current_user.username,
          date_of_birth: current_user.custom_fields['des_date_of_birth'],
          brca_membership_number: current_user.custom_fields['brca_membership_number']
        }
      }
    end

    def update
      if params[:date_of_birth].present?
        current_user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
      end
      if params[:brca_membership_number].present?
        current_user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
      end
      current_user.save!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
