class DesDriverMatchingService
  def initialize(event)
    @event = event
  end

  def match(driver_name)
    # 1. Try transponder number match via booking
    # 2. Try BRCA number match
    # 3. Try name match against username or display name
    user = match_by_name(driver_name)
    user
  end

  def auto_match_all(entries)
    entries.each do |entry|
      next if entry.user_id.present?
      user = match(entry.driver_name)
      if user
        entry.update!(user_id: user.id, match_confirmed: false)
      end
    end
  end

  private

  def match_by_name(driver_name)
    return nil if driver_name.blank?
    normalized = driver_name.downcase.strip

    # Try exact username match
    user = User.find_by("lower(username) = ?", normalized)
    return user if user

    # Try exact name match
    user = User.find_by("lower(name) = ?", normalized)
    return user if user

    # Try partial match — first + last name
    parts = normalized.split
    if parts.length >= 2
      first = parts.first
      last = parts.last
      user = User.where("lower(name) LIKE ?", "%#{first}%#{last}%").first
      return user if user
      user = User.where("lower(name) LIKE ?", "%#{last}%#{first}%").first
      return user if user
    end

    nil
  end
end
