# Default positions
[
  { name: 'Chairman', is_admin: true },
  { name: 'Secretary', is_admin: true },
  { name: 'Treasurer', is_admin: false },
  { name: 'Event Manager', is_admin: true },
  { name: 'Race Director', is_admin: true },
  { name: 'Member', is_admin: false }
].each do |position|
  DesPosition.find_or_create_by!(name: position[:name]) do |p|
    p.is_admin = position[:is_admin]
  end
end

# Default class types
[
  '2WD Buggy', '4WD Buggy', '2WD Iconic', '4WD Iconic',
  'Mixed Buggy', '2WD Stadium', '4WD Stadium', 'Mixed Stadium',
  '2WD Shortcourse', '4WD Shortcourse', 'Mixed Shortcourse',
  'Rally', 'Fun'
].each do |name|
  DesEventClassType.find_or_create_by!(name: name)
end

# Default manufacturers
[
  'Associated RC', 'Tekno', 'Kyosho', 'Xray', 'Mugen',
  'Serpent', 'Yokomo', 'Tamiya', 'Team Losi', 'Arrma',
  'Schumacher', 'HB Racing', 'Capricorn', 'Agama', 'SWorkz'
].each do |name|
  DesManufacturer.find_or_create_by!(name: name) do |m|
    m.status = 'approved'
  end
end

# Default event types
[
  'Race Meeting', 'Club Meeting', 'Championship Round',
  'Regional', 'National', 'Practice'
].each do |name|
  DesEventType.find_or_create_by!(name: name)
end

# Global Class Compatibility Rules
puts "Seeding global class compatibility rules..."
global_rules = [
  # 2WD Buggy
  { class_type_name: '2WD Buggy', rule_type: 'driveline', rule_value: '2WD,Rear Motor' },
  { class_type_name: '2WD Buggy', rule_type: 'chassis', rule_value: '1/10 Buggy' },
  # 4WD Buggy
  { class_type_name: '4WD Buggy', rule_type: 'driveline', rule_value: '4WD' },
  { class_type_name: '4WD Buggy', rule_type: 'chassis', rule_value: '1/10 Buggy' },
  # 2WD Iconic
  { class_type_name: '2WD Iconic', rule_type: 'driveline', rule_value: '2WD,Rear Motor' },
  { class_type_name: '2WD Iconic', rule_type: 'chassis', rule_value: '1/10 Buggy' },
  # 4WD Iconic
  { class_type_name: '4WD Iconic', rule_type: 'driveline', rule_value: '4WD' },
  { class_type_name: '4WD Iconic', rule_type: 'chassis', rule_value: '1/10 Buggy' },
  # Mixed Buggy
  { class_type_name: 'Mixed Buggy', rule_type: 'driveline', rule_value: '2WD,4WD,Rear Motor' },
  { class_type_name: 'Mixed Buggy', rule_type: 'chassis', rule_value: '1/10 Buggy' },
  # 2WD Stadium
  { class_type_name: '2WD Stadium', rule_type: 'driveline', rule_value: '2WD,Rear Motor' },
  { class_type_name: '2WD Stadium', rule_type: 'chassis', rule_value: '1/10 Stadium' },
  # 4WD Stadium
  { class_type_name: '4WD Stadium', rule_type: 'driveline', rule_value: '4WD' },
  { class_type_name: '4WD Stadium', rule_type: 'chassis', rule_value: '1/10 Stadium' },
  # Mixed Stadium
  { class_type_name: 'Mixed Stadium', rule_type: 'driveline', rule_value: '2WD,4WD,Rear Motor' },
  { class_type_name: 'Mixed Stadium', rule_type: 'chassis', rule_value: '1/10 Stadium' },
  # 2WD Shortcourse
  { class_type_name: '2WD Shortcourse', rule_type: 'driveline', rule_value: '2WD,Rear Motor' },
  { class_type_name: '2WD Shortcourse', rule_type: 'chassis', rule_value: '1/10 Short Course' },
  # 4WD Shortcourse
  { class_type_name: '4WD Shortcourse', rule_type: 'driveline', rule_value: '4WD' },
  { class_type_name: '4WD Shortcourse', rule_type: 'chassis', rule_value: '1/10 Short Course' },
  # Mixed Shortcourse
  { class_type_name: 'Mixed Shortcourse', rule_type: 'driveline', rule_value: '2WD,4WD,Rear Motor' },
  { class_type_name: 'Mixed Shortcourse', rule_type: 'chassis', rule_value: '1/10 Short Course' },
  # Rally - all drivetrains
  { class_type_name: 'Rally', rule_type: 'driveline', rule_value: '2WD,4WD,Rear Motor' },
  # Fun - all drivetrains
  { class_type_name: 'Fun', rule_type: 'driveline', rule_value: '2WD,4WD,Rear Motor' },
]

global_rules.each do |rule|
  ct = DesEventClassType.find_by(name: rule[:class_type_name])
  next unless ct
  DesClassCompatibilityRule.find_or_create_by!(
    class_type_id: ct.id,
    rule_type: rule[:rule_type],
    organisation_id: nil
  ) do |r|
    r.rule_value = rule[:rule_value]
  end
end
puts "Global compatibility rules seeded!"
