# frozen_string_literal: true

require 'net/http'
require 'uri'

module Jobs
  class BrcaCalendarSync < ::Jobs::Scheduled
    every 1.week

    ICAL_URL = 'https://www.brca.org/events?format=ics&start=0'.freeze

    # Skip these — international events not relevant to UK club directory
    SKIP_DISCIPLINES = %w[EFRA IFMA].freeze

    # Maps discipline name patterns to scale/power/surface tags
    DISCIPLINE_TAGS = {
      '10th Off Road Truck' => { scale: '1/10', power_type: 'electric', surface: 'off_road' },
      '10th Off Road'       => { scale: '1/10', power_type: 'electric', surface: 'off_road' },
      '10th Electric'       => { scale: '1/10', power_type: 'electric', surface: 'on_road' },
      '10th IC'             => { scale: '1/10', power_type: 'nitro',    surface: 'on_road' },
      '8th Circuit'         => { scale: '1/8',  power_type: 'mixed',    surface: 'on_road' },
      '8th Stockcar'        => { scale: '1/8',  power_type: 'nitro',    surface: 'off_road' },
      '8th RallyX'          => { scale: '1/8',  power_type: 'nitro',    surface: 'off_road' },
      '8th Rally'           => { scale: '1/8',  power_type: 'nitro',    surface: 'off_road' },
      'E-Buggy'             => { scale: '1/8',  power_type: 'mixed',    surface: 'off_road' },
      '12th Oval'           => { scale: '1/12', power_type: 'electric', surface: 'on_road' },
      'GT12'                => { scale: '1/12', power_type: 'electric', surface: 'on_road' },
      'East Anglia'         => { scale: '1/12', power_type: 'electric', surface: 'on_road' },
      'LSOR'                => { scale: 'large_scale', power_type: 'nitro',    surface: 'off_road' },
      'Large Scale On Road' => { scale: 'large_scale', power_type: 'petrol',   surface: 'on_road' },
      'Large Scale Off Road'=> { scale: 'large_scale', power_type: 'nitro',    surface: 'off_road' },
      'M-TC'                => { scale: '1/10', power_type: 'electric', surface: 'on_road' },
      'BRCA M-TC'           => { scale: '1/10', power_type: 'electric', surface: 'on_road' },
      'KOC'                 => { scale: '1/10', power_type: 'electric', surface: 'on_road' },
      '1/10th Off Road'     => { scale: '1/10', power_type: 'electric', surface: 'off_road' },
    }.freeze

    SERIES_PATTERNS = {
      /national/i  => 'national',
      /regional/i  => 'regional',
      /clubman/i   => 'clubman',
      /affiliated/i=> 'affiliated',
    }.freeze

    REGION_PATTERNS = [
      'North West', 'North East', 'East Mids', 'West Mids',
      'East Anglia', 'East Of England', 'South West', 'South East',
      'Mid South', 'Mid East', 'Mid West', 'Welsh', 'Scottish'
    ].freeze

    def execute(args)
      Rails.logger.info('[BrcaCalendarSync] Starting BRCA calendar sync')

      raw_ical = fetch_ical
      return Rails.logger.warn('[BrcaCalendarSync] Failed to fetch iCal feed') unless raw_ical

      raw_events = parse_ical(raw_ical)
      Rails.logger.info("[BrcaCalendarSync] Parsed #{raw_events.length} raw events")

      # Skip EFRA/IFMA
      raw_events.reject! { |e| should_skip?(e[:title]) }

      # Group events by date + venue (GPS or location string)
      grouped = group_events(raw_events)
      Rails.logger.info("[BrcaCalendarSync] Grouped into #{grouped.length} events")

      # Find BRCA organisation
      brca_org_id = DesOrganisation.find_by(name: 'BRCA')&.id

      synced = 0
      grouped.each do |group|
        upsert_event(group, brca_org_id)
        synced += 1
      end

      Rails.logger.info("[BrcaCalendarSync] Sync complete — #{synced} events upserted")
    rescue => e
      Rails.logger.error("[BrcaCalendarSync] Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    end

    private

    def fetch_ical
      uri = URI.parse(ICAL_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 30
      http.read_timeout = 360  # BRCA site is slow — allow 2 minutes
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      return nil unless response.code == '200'
      response.body
    rescue => e
      Rails.logger.error("[BrcaCalendarSync] Fetch error: #{e.message}")
      nil
    end

    def parse_ical(raw)
      events = []
      current = {}

      raw.each_line do |line|
        line = line.strip.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')

        case line
        when 'BEGIN:VEVENT'
          current = {}
        when 'END:VEVENT'
          events << current.dup if current[:uid].present?
          current = {}
        when /^UID:(.+)/
          current[:uid] = $1.strip
        when /^SUMMARY:(.+)/
          current[:title] = $1.strip
        when /^LOCATION:(.+)/
          current[:location] = $1.strip.gsub('\\,', ',')
        when /^DTSTART:(.+)/
          current[:starts_at] = parse_ical_date($1.strip)
        when /^DTEND:(.+)/
          current[:ends_at] = parse_ical_date($1.strip)
        when /^GEO:(.+)/
          parts = $1.strip.split(';')
          current[:lat] = parts[0].to_f
          current[:lng] = parts[1].to_f
        when /^X-TITLE=([^:;]+)/
          current[:venue_name] = $1.strip
        when /^X-APPLE-STRUCTURED-LOCATION.*X-TITLE=([^:;]+)/
          current[:venue_name] = $1.strip unless current[:venue_name].present?
        end
      end

      events
    end

    def parse_ical_date(str)
      if str =~ /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$/
        Time.utc($1, $2, $3, $4, $5, $6)
      elsif str =~ /^(\d{4})(\d{2})(\d{2})$/
        Time.utc($1, $2, $3)
      end
    rescue
      nil
    end

    def should_skip?(title)
      return true if title.blank?
      SKIP_DISCIPLINES.any? { |d| title.upcase.include?(d.upcase) }
    end

    def group_events(events)
      groups = {}

      events.each do |e|
        next unless e[:starts_at].present? && e[:title].present?

        # Group key: same start date + same GPS location (rounded to 3dp) or location string
        date_key = e[:starts_at].strftime('%Y-%m-%d')
        loc_key = if e[:lat].present? && e[:lng].present?
          "#{e[:lat].round(3)},#{e[:lng].round(3)}"
        else
          e[:location].to_s.downcase.strip
        end

        group_key = "#{date_key}|#{loc_key}"

        if groups[group_key]
          groups[group_key][:uids] << e[:uid]
          groups[group_key][:classes] << extract_class(e[:title])
        else
          groups[group_key] = {
            uids: [e[:uid]],
            title: clean_title(e[:title]),
            discipline: extract_discipline(e[:title]),
            series_type: extract_series_type(e[:title]),
            region: extract_region(e[:title]),
            round_number: extract_round(e[:title]),
            classes: [extract_class(e[:title])].compact,
            starts_at: e[:starts_at],
            ends_at: e[:ends_at],
            location: e[:location],
            lat: e[:lat],
            lng: e[:lng],
            venue_name: e[:venue_name],
          }
        end
      end

      groups.values.map do |g|
        g[:classes] = g[:classes].compact.uniq
        tags = tags_for_discipline(g[:discipline])
        g.merge(tags)
      end
    end

    def upsert_event(group, organisation_id = nil)
      # Find or match venue
      venue = find_or_create_venue(group)

      # Use first UID as stable identifier, store all UIDs
      primary_uid = group[:uids].first
      all_uids = group[:uids].to_json

      existing = DesImportedEvent.find_by(
        "external_uids::text LIKE ?", "%#{primary_uid}%"
      )

      attrs = {
        source: 'brca',
        external_uids: all_uids,
        title: group[:title],
        discipline: group[:discipline],
        series_type: group[:series_type],
        region: group[:region],
        round_number: group[:round_number],
        classes_raw: group[:classes].to_json,
        scale: group[:scale],
        power_type: group[:power_type],
        surface: group[:surface],
        starts_at: group[:starts_at],
        ends_at: group[:ends_at],
        venue_id: venue&.id,
        booking_url: "https://www.brca.org/events",
        organisation_id: organisation_id
      }

      if existing
        existing.update!(attrs)
      else
        DesImportedEvent.create!(attrs)
      end
    end

    def find_or_create_venue(group)
      return nil unless group[:location].present? || group[:lat].present?

      # Try GPS match first (within ~100m = 0.001 degrees)
      if group[:lat].present? && group[:lng].present?
        venue = DesVenue.where(
          "ABS(latitude - ?) < 0.001 AND ABS(longitude - ?) < 0.001",
          group[:lat], group[:lng]
        ).first
        return venue if venue
      end

      # Try postcode match
      postcode = extract_postcode(group[:location].to_s)
      if postcode.present?
        venue = DesVenue.find_by("LOWER(postcode) = ?", postcode.downcase.gsub(' ', ''))
        return venue if venue
      end

      # Create stub venue
      name = group[:venue_name].presence ||
             extract_venue_name_from_location(group[:location].to_s) ||
             "Venue (#{group[:location].to_s.first(30)})"

      DesVenue.create!(
        name: name,
        address: group[:location],
        postcode: postcode,
        latitude: group[:lat],
        longitude: group[:lng],
        status: 'approved',
        source: 'brca_import',
        is_stub: true,
        claim_status: 'unclaimed'
      )
    rescue => e
      Rails.logger.warn("[BrcaCalendarSync] Could not create venue: #{e.message}")
      nil
    end

    def extract_postcode(location)
      location.match(/\b([A-Z]{1,2}\d{1,2}[A-Z]?\s*\d[A-Z]{2})\b/i)&.captures&.first&.upcase
    end

    def extract_venue_name_from_location(location)
      # Try to get a sensible name from the location string
      parts = location.split(',')
      parts.first.strip if parts.first.present?
    end

    def clean_title(title)
      # Remove class in brackets and year
      title
        .gsub(/\s*\([^)]+\)\s*$/, '')
        .gsub(/\s+20\d\d\s+/, ' ')
        .gsub(/\s+20\d\d$/, '')
        .gsub(/\s+Round\s+\d+.*$/i, '')
        .strip
    end

    def extract_class(title)
      title.match(/\(([^)]+)\)/)&.captures&.first&.strip
    end

    def extract_discipline(title)
      DISCIPLINE_TAGS.keys.find { |d| title.downcase.include?(d.downcase) } ||
        title.split(/\s+(?:Nationals?|Regionals?|Series|20\d\d)/i).first.to_s.strip
    end

    def extract_series_type(title)
      SERIES_PATTERNS.each do |pattern, type|
        return type if title.match?(pattern)
      end
      nil
    end

    def extract_region(title)
      REGION_PATTERNS.find { |r| title.include?(r) }
    end

    def extract_round(title)
      title.match(/Round\s+(\d+)/i)&.captures&.first&.to_i
    end

    def tags_for_discipline(discipline)
      return { scale: nil, power_type: nil, surface: nil } if discipline.blank?
      DISCIPLINE_TAGS.find { |k, _| discipline.downcase.include?(k.downcase) }&.last ||
        { scale: nil, power_type: nil, surface: nil }
    end
  end
end
