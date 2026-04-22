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
