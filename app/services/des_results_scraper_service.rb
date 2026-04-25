require 'net/http'
require 'nokogiri'

class DesResultsScraperService
  BASE_URL = 'https://rc-results.com'

  def initialize(meeting_id)
    @meeting_id = meeting_id
  end

  def scrape
    summary_url = "#{BASE_URL}/Viewer/Main/MeetingSummary?meetingId=#{@meeting_id}"
    html = fetch(summary_url)
    doc = Nokogiri::HTML(html)

    result = []
    current_round = nil

    doc.css("h4, a[href*='RaceResult']").each do |node|
      if node.name == "h4"
        current_round = node.text.strip
      elsif node.name == "a" && current_round
        race_name = node.text.strip
        next unless race_name.downcase.include?("final")

        href = node["href"]
        race_id = href.match(/raceId=(\d+)/)&.[](1)&.to_i
        next unless race_id

        entries = scrape_race(race_id)
        class_name = extract_class_name(race_name)
        final_type = extract_final_type(race_name)

        result << {
          round_name: current_round,
          race_name: race_name,
          class_name: class_name,
          final_type: final_type,
          rc_results_race_id: race_id,
          entries: entries
        }
      end
    end

    result
  end


  private

  def scrape_race(race_id)
    url = "#{BASE_URL}/Viewer/Main/RaceResult?raceId=#{race_id}"
    html = fetch(url)
    doc = Nokogiri::HTML(html)

    entries = []
    doc.css('table tr').each_with_index do |row, i|
      next if i == 0
      cols = row.css('td')
      next if cols.empty?

      driver_link = cols[2]&.css('a')&.first
      driver_name = driver_link&.text&.strip || cols[2]&.text&.strip
      next if driver_name.blank?

      result_text = cols[3]&.text&.strip
      laps, race_time = parse_result(result_text)

      entries << {
        position: cols[0]&.text&.strip&.to_i,
        car_number: cols[1]&.text&.strip,
        driver_name: driver_name,
        laps: laps,
        race_time: race_time,
        best_lap: cols[5]&.text&.strip
      }
    end

    entries
  end

  def parse_result(result_text)
    return [nil, nil] if result_text.blank?
    parts = result_text.split('/')
    laps = parts[0]&.strip&.to_i
    race_time = parts[1]&.strip
    [laps, race_time]
  end

  def extract_class_name(race_name)
    race_name.gsub(/Race \d+ - /, '').gsub(/ - [ABC] Final$/, '').gsub(/ Final$/, '').strip
  end

  def extract_final_type(race_name)
    match = race_name.match(/- ([ABC]) Final/)
    match ? match[1] : 'A'
  end

  def fetch(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    raise "Failed to fetch #{url}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    response.body
  end
end
