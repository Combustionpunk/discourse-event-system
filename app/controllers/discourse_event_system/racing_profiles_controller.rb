# frozen_string_literal: true

module DiscourseEventSystem
  class RacingProfilesController < ApplicationController
    before_action :ensure_logged_in

    def show
      render json: {
        user: {
          id: current_user.id,
          username: current_user.username,
          date_of_birth: current_user.custom_fields['des_date_of_birth'] || current_user.date_of_birth&.to_s,
          brca_membership_number: current_user.custom_fields['brca_membership_number']
        }
      }
    end

    def update
      if params[:date_of_birth].present?
        current_user.date_of_birth = Date.parse(params[:date_of_birth])
        current_user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
      end
      if params[:brca_membership_number].present?
        current_user.custom_fields['brca_membership_number'] = params[:brca_membership_number]
      end
      current_user.save_custom_fields
      current_user.save!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # === DEPENDANTS (users I am guardian of) ===

    def family_members
      records = DesRacingFamilyMember.for_guardian(current_user.id).includes(:user)
      render json: {
        family_members: records.map { |fm| serialize_dependant(fm) }
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

        user = User.new(username: username, name: name, email: email, password: password, active: true, approved: true, trust_level: 1)
        user.skip_email_validation = true if email.end_with?('@rcmisfits.noreply')

        unless user.save
          return render json: { error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end

        user.email_tokens.update_all(confirmed: true)
        user.activate

        if params[:date_of_birth].present?
          user.date_of_birth = Date.parse(params[:date_of_birth])
          user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
        end
        user.custom_fields['brca_membership_number'] = params[:brca_membership_number] if params[:brca_membership_number].present?
        user.save_custom_fields
        user.save!

        record = DesRacingFamilyMember.create!(
          user_id: user.id,
          family_member_user_id: user.id,
          guardian_user_id: current_user.id,
          created_by_guardian: true
        )

        DesBadgeService.check_family_badge(current_user) rescue nil
        render json: { success: true, created: true, password: password, user: serialize_dependant(record) }
      else
        user = User.find_by(username: params[:username])
        return render json: { error: 'User not found' }, status: :not_found unless user

        record = DesRacingFamilyMember.create!(
          user_id: user.id,
          family_member_user_id: user.id,
          guardian_user_id: current_user.id,
          created_by_guardian: false
        )

        DesBadgeService.check_family_badge(current_user) rescue nil
        render json: { success: true, created: false, user: serialize_dependant(record) }
      end
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def remove_family_member
      fm = DesRacingFamilyMember.find_by(user_id: params[:user_id], guardian_user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless fm
      fm.destroy!
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_family_member
      fm = DesRacingFamilyMember.find_by(user_id: params[:user_id], guardian_user_id: current_user.id)
      return render json: { error: 'Not found' }, status: :not_found unless fm
      member_user = fm.user

      if params[:date_of_birth].present?
        member_user.date_of_birth = Date.parse(params[:date_of_birth])
        member_user.custom_fields['des_date_of_birth'] = params[:date_of_birth]
      end
      member_user.custom_fields['brca_membership_number'] = params[:brca_membership_number].presence if params.key?(:brca_membership_number)
      member_user.save_custom_fields
      member_user.save!

      render json: { success: true, user: serialize_dependant(fm.reload) }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    # === GUARDIAN (who is my parent/guardian) ===

    def my_guardian
      record = DesRacingFamilyMember.for_child(current_user.id).includes(:guardian).first
      if record
        render json: {
          guardian: {
            user_id: record.guardian_user_id,
            username: record.guardian.username,
            name: record.guardian.name,
            avatar_url: record.guardian.avatar_template&.gsub('{size}', '45')
          }
        }
      else
        render json: { guardian: nil }
      end
    end

    def set_guardian
      guardian = User.find_by(username: params[:username])
      return render json: { error: 'User not found' }, status: :not_found unless guardian
      raise "Cannot set yourself as guardian" if guardian.id == current_user.id

      DesRacingFamilyMember.for_child(current_user.id).where(created_by_guardian: false).destroy_all

      record = DesRacingFamilyMember.create!(
        user_id: current_user.id,
        family_member_user_id: current_user.id,
        guardian_user_id: guardian.id,
        created_by_guardian: false
      )

      render json: {
        success: true,
        guardian: {
          user_id: guardian.id,
          username: guardian.username,
          name: guardian.name,
          avatar_url: guardian.avatar_template&.gsub('{size}', '45')
        }
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def remove_guardian
      DesRacingFamilyMember.for_child(current_user.id).where(created_by_guardian: false).destroy_all
      render json: { success: true }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def serialize_dependant(fm)
      u = fm.user
      {
        user_id: u.id,
        username: u.username,
        name: u.name,
        avatar_url: u.avatar_template&.gsub('{size}', '45'),
        date_of_birth: u.custom_fields&.dig('des_date_of_birth') || u.date_of_birth&.to_s,
        brca_membership_number: u.custom_fields&.dig('brca_membership_number'),
        created_by_guardian: fm.created_by_guardian
      }
    end
  end
end
