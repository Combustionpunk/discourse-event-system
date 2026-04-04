# frozen_string_literal: true

module DiscourseEventSystem
  class RacingProfilesController < ApplicationController
    before_action :ensure_logged_in

    def show
      transponders = DesUserTransponder
        .where(user_id: current_user.id)
        .includes(:class_type)

      class_types = DesEventClassType.all

      render json: {
        user: {
          id: current_user.id,
          username: current_user.username,
          date_of_birth: current_user.custom_fields['des_date_of_birth'],
          brca_membership_number: current_user.custom_fields['brca_membership_number']
        },
        transponders: transponders.map do |t|
          {
            id: t.id,
            class_type_id: t.class_type_id,
            class_type_name: t.class_type.name,
            transponder_number: t.transponder_number
          }
        end,
        class_types: class_types.map do |ct|
          { id: ct.id, name: ct.name }
        end
      }
    end

    def update
      # Update date of birth
      if params[:date_of_birth].present?
        current_user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
      end

      # Update BRCA number
      if params[:brca_membership_number].present?
        current_user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
      end

      current_user.save!

      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def add_transponder
      transponder = DesUserTransponder.find_or_initialize_by(
        user_id: current_user.id,
        class_type_id: params[:class_type_id]
      )
      transponder.transponder_number = params[:transponder_number]

      if transponder.save
        render json: {
          id: transponder.id,
          class_type_id: transponder.class_type_id,
          class_type_name: transponder.class_type.name,
          transponder_number: transponder.transponder_number
        }, status: :created
      else
        render json: { errors: transponder.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def remove_transponder
      transponder = DesUserTransponder.find_by(
        id: params[:id],
        user_id: current_user.id
      )

      if transponder
        transponder.destroy
        render json: { success: true }
      else
        render json: { error: 'Transponder not found' }, status: :not_found
      end
    end
  end
end
