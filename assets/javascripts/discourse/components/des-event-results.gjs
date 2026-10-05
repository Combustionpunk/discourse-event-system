import { i18n } from "discourse-i18n";

const PodiumPosition = <template>
  <div class="podium-position podium-{{@place}}">
    <div class="podium-trophy">{{@trophy}}</div>
    {{#if @entry.user}}
      <a
        data-user-card={{@entry.user.username}}
        href="/u/{{@entry.user.username}}"
      >
        <img
          alt={{@entry.user.username}}
          class="podium-avatar"
          height="60"
          src={{@entry.user.avatar_url}}
          width="60"
        />
      </a>
      <span class="podium-name">{{@entry.user.username}}</span>
    {{else}}
      <div class="podium-avatar podium-avatar--unknown">?</div>
      <span class="podium-name">{{@entry.driver_name}}</span>
    {{/if}}
  </div>
</template>;

const DriverName = <template>
  {{#if @entry.user}}
    <a
      data-user-card={{@entry.user.username}}
      href="/u/{{@entry.user.username}}"
    >{{@entry.user.username}}</a>
  {{else}}
    {{@entry.driver_name}}
  {{/if}}
</template>;

// Podium per class plus the full finals tables, from /des/events/:id/results.
const DesEventResults = <template>
  <div class="event-results-section">
    <h2 class="results-heading">{{i18n
        "discourse_event_system.event_results.heading"
      }}</h2>

    <div class="podium-cards">
      {{#each @results.class_summaries as |summary|}}
        <div class="podium-card">
          <h3 class="podium-class-name">{{summary.class_name}}</h3>
          <div class="podium-positions">
            <PodiumPosition
              @entry={{summary.first}}
              @place="first"
              @trophy="🥇"
            />
            <PodiumPosition
              @entry={{summary.second}}
              @place="second"
              @trophy="🥈"
            />
            <PodiumPosition
              @entry={{summary.third}}
              @place="third"
              @trophy="🥉"
            />
          </div>

          {{#if summary.fastest_lap.driver_name}}
            <div class="podium-fastest-lap">
              <span>{{i18n
                  "discourse_event_system.event_results.fastest_lap"
                }}</span>
              <DriverName @entry={{summary.fastest_lap}} />
              <span class="fastest-lap-time">
                —
                {{i18n
                  "discourse_event_system.event_results.lap_time"
                  time=summary.fastest_lap.extra
                }}</span>
            </div>
          {{/if}}
        </div>
      {{/each}}
    </div>

    <div class="full-results">
      <h3>{{i18n "discourse_event_system.event_results.full_finals"}}</h3>
      {{#each @results.races as |race|}}
        <div class="results-race-section">
          <h4>{{race.race_name}}</h4>
          <table class="results-table">
            <thead>
              <tr>
                <th>{{i18n
                    "discourse_event_system.event_results.columns.position"
                  }}</th>
                <th>{{i18n
                    "discourse_event_system.event_results.columns.car"
                  }}</th>
                <th>{{i18n
                    "discourse_event_system.event_results.columns.driver"
                  }}</th>
                <th>{{i18n
                    "discourse_event_system.event_results.columns.laps_time"
                  }}</th>
                <th>{{i18n
                    "discourse_event_system.event_results.columns.best_lap"
                  }}</th>
              </tr>
            </thead>
            <tbody>
              {{#each race.entries as |entry|}}
                <tr>
                  <td>{{entry.position}}</td>
                  <td>{{entry.car_number}}</td>
                  <td><DriverName @entry={{entry}} /></td>
                  <td>{{entry.laps}} / {{entry.race_time}}</td>
                  <td>{{entry.best_lap}}</td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{/each}}
    </div>
  </div>
</template>;

export default DesEventResults;
