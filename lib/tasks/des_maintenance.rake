desc "Recalculate all event class statuses (sold_out/active)"
task "des:recalculate_class_statuses" => :environment do
  count = 0
  DesEventClass.find_each do |ec|
    old_status = ec.status
    ec.update_status!
    if ec.status != old_status
      puts "Class #{ec.id} (#{ec.name}): #{old_status} -> #{ec.status} (#{ec.confirmed_bookings_count}/#{ec.capacity})"
      count += 1
    end
  end
  puts "Done. #{count} class(es) updated."
end

desc "Retroactively award badges to all qualifying users"
task "des:award_retroactive_badges" => :environment do
  before_count = UserBadge.count
  users_checked = 0

  # Users with confirmed bookings
  DesEventBooking.where(status: 'confirmed').select(:user_id).distinct.pluck(:user_id).each do |uid|
    user = User.find_by(id: uid)
    next unless user
    DesBadgeService.check_booking_badges(user)
    users_checked += 1
  end
  puts "Checked #{users_checked} users with bookings"

  # Users with cars
  DesUserCar.active.select(:user_id).distinct.pluck(:user_id).each do |uid|
    user = User.find_by(id: uid)
    next unless user
    DesBadgeService.check_garage_badge(user)
  end
  puts "Checked garage badges"

  # Users with memberships
  DesOrganisationMembership.active.select(:user_id).distinct.pluck(:user_id).each do |uid|
    user = User.find_by(id: uid)
    next unless user
    DesBadgeService.check_membership_badge(user)
  end
  puts "Checked membership badges"

  # Users who are guardians
  DesRacingFamilyMember.select(:guardian_user_id).distinct.pluck(:guardian_user_id).each do |uid|
    user = User.find_by(id: uid)
    next unless user
    DesBadgeService.check_family_badge(user)
  end
  puts "Checked family badges"

  awarded = UserBadge.count - before_count
  puts "Done. #{awarded} badge(s) awarded retroactively."
end
