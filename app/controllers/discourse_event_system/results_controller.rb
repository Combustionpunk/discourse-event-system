module DiscourseEventSystem
  class ResultsController < ::ApplicationController
    before_action :ensure_logged_in
    before_action :set_event

    def show
      result = DesEventResult.includes(
        races: :entries,
        class_summaries: [:first_user, :second_user, :third_user, :fastest_lap_user]
      ).find_by(event_id: @event.id)

      if result
        render json: serialize_result(result)
      else
        render json: { status: 'none' }
      end
    end

    def import
      ensure_event_admin!
      raise Discourse::InvalidAccess unless @event.rc_results_meeting_id.present?

      # Delete existing result if re-importing
      DesEventResult.where(event_id: @event.id).destroy_all

      scraper = DesResultsScraperService.new(@event.rc_results_meeting_id)
      races_data = scraper.scrape

      event_result = DesEventResult.create!(
        event_id: @event.id,
        status: 'pending_match',
        imported_at: Time.now
      )

      races_data.each do |race_data|
        race = DesEventResultRace.create!(
          event_result_id: event_result.id,
          round_name: race_data[:round_name],
          race_name: race_data[:race_name],
          class_name: race_data[:class_name],
          final_type: race_data[:final_type],
          rc_results_race_id: race_data[:rc_results_race_id]
        )

        race_data[:entries].each do |entry_data|
          DesEventResultEntry.create!(
            race_id: race.id,
            position: entry_data[:position],
            car_number: entry_data[:car_number],
            driver_name: entry_data[:driver_name],
            laps: entry_data[:laps],
            race_time: entry_data[:race_time],
            best_lap: entry_data[:best_lap]
          )
        end
      end

      # Auto-match drivers
      matcher = DesDriverMatchingService.new(@event)
      all_entries = DesEventResultEntry.joins(:race).where(des_event_result_races: { event_result_id: event_result.id })
      matcher.auto_match_all(all_entries)

      render json: serialize_result(event_result.reload)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update_matches
      ensure_event_admin!
      result = DesEventResult.find_by!(event_id: @event.id)

      params[:matches].each do |entry_id, user_id|
        entry = DesEventResultEntry.find(entry_id)
        entry.update!(
          user_id: user_id.present? ? user_id.to_i : nil,
          match_confirmed: true
        )
      end

      render json: serialize_result(result.reload)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def publish
      ensure_event_admin!
      result = DesEventResult.find_by!(event_id: @event.id)

      # Build class summaries
      build_class_summaries(result)

      # Award badges
      award_badges(result)

      result.update!(status: 'published')
      render json: serialize_result(result.reload)
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_event
      @event = DesEvent.find(params[:event_id])
    end

    def ensure_event_admin!
      raise Discourse::InvalidAccess unless current_user.admin? ||
        DesOrganisationMember.joins(:position)
          .where(organisation_id: @event.organisation_id, user_id: current_user.id)
          .where(des_positions: { is_admin: true }).exists?
    end

    def build_class_summaries(event_result)
      DesEventResultClassSummary.where(event_result_id: event_result.id).destroy_all

      # Group races by class
      races_by_class = event_result.races.group_by(&:class_name)

      races_by_class.each do |class_name, races|
        # A Final determines podium positions
        a_final = races.find { |r| r.final_type == 'A' } || races.first
        a_entries = a_final.entries.order(:position)

        first_entry  = a_entries[0]
        second_entry = a_entries[1]
        third_entry  = a_entries[2]

        # Fastest lap across ALL finals for this class
        all_entries = races.flat_map(&:entries)
        fastest_entry = all_entries
          .select { |e| e.best_lap.present? && e.best_lap.match?(/\d/) }
          .min_by { |e| e.best_lap.to_f }

        DesEventResultClassSummary.create!(
          event_result_id: event_result.id,
          class_name: class_name,
          first_user_id: first_entry&.user_id,
          second_user_id: second_entry&.user_id,
          third_user_id: third_entry&.user_id,
          first_driver_name: first_entry&.driver_name,
          second_driver_name: second_entry&.driver_name,
          third_driver_name: third_entry&.driver_name,
          fastest_lap_user_id: fastest_entry&.user_id,
          fastest_lap_driver_name: fastest_entry&.driver_name,
          fastest_lap_time: fastest_entry&.best_lap
        )
      end
    end

    def award_badges(event_result)
      org = @event.organisation
      badge_names = {
        gold:        "#{org.name} Gold",
        silver:      "#{org.name} Silver",
        bronze:      "#{org.name} Bronze",
        fastest_lap: "#{org.name} Fastest Lap"
      }

      badges = badge_names.transform_values do |name|
        Badge.find_by(name: name) || Badge.create!(
          name: name,
          badge_type_id: 3, # Gold type
          description: "Awarded at #{org.name} championship events",
          allow_title: false,
          multiple_grant: true
        )
      end

      event_result.class_summaries.each do |summary|
        [
          [summary.first_user_id,       badges[:gold]],
          [summary.second_user_id,      badges[:silver]],
          [summary.third_user_id,       badges[:bronze]],
          [summary.fastest_lap_user_id, badges[:fastest_lap]]
        ].each do |user_id, badge|
          next unless user_id.present?
          BadgeGranter.grant(badge, User.find(user_id), granted_by: current_user)
        end
      end
    end

    def serialize_result(result)
      {
        id: result.id,
        status: result.status,
        imported_at: result.imported_at,
        races: result.races.map do |race|
          {
            id: race.id,
            round_name: race.round_name,
            race_name: race.race_name,
            class_name: race.class_name,
            final_type: race.final_type,
            entries: race.entries.order(:position).map do |entry|
              {
                id: entry.id,
                position: entry.position,
                driver_name: entry.driver_name,
                car_number: entry.car_number,
                laps: entry.laps,
                race_time: entry.race_time,
                best_lap: entry.best_lap,
                user_id: entry.user_id,
                match_confirmed: entry.match_confirmed,
                user: entry.user ? {
                  id: entry.user.id,
                  username: entry.user.username,
                  name: entry.user.name,
                  avatar_template: entry.user.avatar_template
                } : nil
              }
            end
          }
        end,
        class_summaries: result.class_summaries.map do |summary|
          {
            class_name: summary.class_name,
            first:  podium_entry(summary.first_user,  summary.first_driver_name),
            second: podium_entry(summary.second_user, summary.second_driver_name),
            third:  podium_entry(summary.third_user,  summary.third_driver_name),
            fastest_lap: podium_entry(summary.fastest_lap_user, summary.fastest_lap_driver_name, summary.fastest_lap_time)
          }
        end
      }
    end

    def podium_entry(user, driver_name, extra = nil)
      {
        driver_name: driver_name,
        user: user ? {
          id: user.id,
          username: user.username,
          name: user.name,
          avatar_template: user.avatar_template
        } : nil,
        extra: extra
      }
    end
  end
end
