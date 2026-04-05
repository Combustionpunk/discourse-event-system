# frozen_string_literal: true

module Jobs
  class MembershipExpiryCheck < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      check_expiring_memberships(7)
      check_expiring_memberships(1)
      check_expired_memberships
    end

    private

    def check_expiring_memberships(days)
      target_date = Time.now + days.days
      start_of_day = target_date.beginning_of_day
      end_of_day = target_date.end_of_day

      memberships = DesOrganisationMembership
        .where(status: 'active')
        .where(expires_at: start_of_day..end_of_day)
        .includes(:user, :organisation, :membership_type)

      memberships.each do |membership|
        DiscourseEventSystem::EventMailer
          .membership_expiry_reminder(membership, days)
          .deliver_later
      rescue => e
        Rails.logger.error "Failed to send expiry reminder for membership #{membership.id}: #{e.message}"
      end
    end

    def check_expired_memberships
      expired = DesOrganisationMembership
        .where(status: 'active')
        .where('expires_at < ?', Time.now)
        .includes(:user, :organisation, :membership_type)

      expired.each do |membership|
        membership.expire!
        DiscourseEventSystem::EventMailer
          .membership_expired(membership)
          .deliver_later
      rescue => e
        Rails.logger.error "Failed to process expired membership #{membership.id}: #{e.message}"
      end
    end
  end
end
