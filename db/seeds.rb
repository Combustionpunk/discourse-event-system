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
