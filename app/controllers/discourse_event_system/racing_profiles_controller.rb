# frozen_string_literal: true

module DiscourseEventSystem
  class RacingProfilesController < ApplicationController
    before_action :ensure_logged_in

    def show
      render json: {
        user: {
          id: current_user.id,
          username: current_user.username,
          date_of_birth: current_user.date_of_birth,
          brca_membership_number: current_user.custom_fields['brca_membership_number']
        }
      }
    end

    def update
      if params[:date_of_birth].present?
        current_user.date_of_birth = Date.parse(params[:date_of_birth])
      end
      if params[:brca_membership_number].present?
        current_user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
      end
      current_user.save!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def family_members
      members = DesRacingFamilyMember.where(user_id: current_user.id).includes(:family_member)
      render json: {
        family_members: members.map { |fm|
          u = fm.family_member
          {
            user_id: u.id,
            username: u.username,
            name: u.name,
            avatar_url: u.avatar_template&.gsub('{size}', '45'),
            date_of_birth: u.custom_fields&.dig('des_date_of_birth'),
            brca_membership_number: u.custom_fields&.dig('brca_membership_number')
          }
        }
      }
    end

    def add_family_member
      if params[:create_user].present?
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

        if params[:date_of_birth].present?
          user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
        end
        if params[:brca_membership_number].present?
          user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
        end
        user.save_custom_fields

        DesRacingFamilyMember.create!(user_id: current_user.id, family_member_user_id: user.id)

        render json: {
          success: true,
          created: true,
          password: password,
          user: serialize_family_member(user)
        }
      else
        user = User.find_by(username: params[:username])
        return render json: { error: 'User not found' }, status: :not_found unless user

        DesRacingFamilyMember.create!(user_id: current_user.id, family_member_user_id: user.id)

        render json: {
          success: true,
          created: false,
          user: serialize_family_member(user)
        }
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def remove_family_member
      fm = DesRacingFamilyMember.find_by(user_id: current_user.id, family_member_user_id: params[:user_id])
      return render json: { error: 'Not found' }, status: :not_found unless fm
      fm.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_family_member
      fm = DesRacingFamilyMember.find_by(user_id: current_user.id, family_member_user_id: params[:user_id])
      return render json: { error: 'Not found' }, status: :not_found unless fm
      member_user = fm.family_member

      if params[:date_of_birth].present?
        member_user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
      end
      if params.key?(:brca_membership_number)
        member_user.custom_fields['brca_membership_number'] = params[:brca_membership_number].presence
      end
      member_user.save_custom_fields

      render json: {
        success: true,
        user: serialize_family_member(member_user)
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def serialize_family_member(user)
      {
        user_id: user.id,
        username: user.username,
        name: user.name,
        avatar_url: user.avatar_template&.gsub('{size}', '45'),
        date_of_birth: user.custom_fields&.dig('des_date_of_birth'),
        brca_membership_number: user.custom_fields&.dig('brca_membership_number')
      }
    end
  end
end
