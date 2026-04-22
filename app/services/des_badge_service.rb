# frozen_string_literal: true

class DesBadgeService
  BOOKING_BADGES = {
    1 => "First Start",
    10 => "Regular Racer",
    25 => "Seasoned Racer",
    50 => "Veteran Racer",
    100 => "Elite Racer"
  }.freeze

  def self.check_booking_badges(user)
    count = DesEventBooking.where(user_id: user.id, status: 'confirmed').count
    BOOKING_BADGES.each do |threshold, badge_name|
      next if count < threshold
      badge = Badge.find_by(name: badge_name)
      next unless badge&.enabled
      BadgeGranter.grant(badge, user) unless UserBadge.exists?(badge_id: badge.id, user_id: user.id)
    end
  rescue => e
    Rails.logger.error "DesBadgeService booking badges error: #{e.message}"
  end

  def self.check_garage_badge(user)
    badge = Badge.find_by(name: "Pit Crew")
    return unless badge&.enabled
    BadgeGranter.grant(badge, user) unless UserBadge.exists?(badge_id: badge.id, user_id: user.id)
  rescue => e
    Rails.logger.error "DesBadgeService garage badge error: #{e.message}"
  end

  def self.check_membership_badge(user)
    badge = Badge.find_by(name: "Club Member")
    return unless badge&.enabled
    BadgeGranter.grant(badge, user) unless UserBadge.exists?(badge_id: badge.id, user_id: user.id)
  rescue => e
    Rails.logger.error "DesBadgeService membership badge error: #{e.message}"
  end

  def self.check_family_badge(user)
    badge = Badge.find_by(name: "Family Racer")
    return unless badge&.enabled
    BadgeGranter.grant(badge, user) unless UserBadge.exists?(badge_id: badge.id, user_id: user.id)
  rescue => e
    Rails.logger.error "DesBadgeService family badge error: #{e.message}"
  end
end
