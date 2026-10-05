import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import DesEventResults from "../components/des-event-results";

export default <template>
  {{#if @controller.model.unavailable}}
    <div class="event-detail-container">
      <p class="event-unavailable">{{i18n
          "discourse_event_system.event_detail.unavailable"
        }}</p>
    </div>
  {{else}}
  <div class="event-detail-container">
    <div class="event-detail-header">
      <h1>{{@controller.model.title}}</h1>
      <span class="event-status event-status--{{@controller.model.status}}">
        {{@controller.model.status}}
      </span>
    </div>

    {{!-- 1. Organisation Card --}}
    <div class="event-section-card">
      <div class="event-org-row">
        {{#if @controller.model.organisation.logo_url}}
          <img alt="" class="org-logo org-logo--large" src={{@controller.model.organisation.logo_url}} />
        {{/if}}
        <div>
          <h3><LinkTo @model={{@controller.model.organisation.id}} @route="organisation">{{@controller.model.organisation.name}}</LinkTo></h3>
          <div class="event-detail-meta-item">📅 {{@controller.model.formatted_date}}</div>
        </div>
      </div>
    </div>

    {{!-- 2. Venue Card --}}
    {{#if @controller.model.venue}}
      <div class="event-venue-card">
        <h3><LinkTo @model={{@controller.model.venue.id}} @route="venue">{{@controller.model.venue.name}}</LinkTo></h3>
        {{#if @controller.model.venue.address}}<div class="venue-detail-item">📍 {{@controller.model.venue.address}}</div>{{/if}}
        {{#if @controller.model.venue.google_maps_url}}<div class="venue-detail-item"><a href={{@controller.model.venue.google_maps_url}} rel="noopener noreferrer" target="_blank">🗺️ View on Google Maps</a></div>{{/if}}
        <div class="venue-badges">
          {{#each @controller.model.venue.tracks as |track|}}
            {{#if track.surface}}<span class="venue-badge venue-badge--surface">{{track.surface}}</span>{{/if}}
            {{#if track.environment}}<span class="venue-badge venue-badge--environment">{{track.environment}}</span>{{/if}}
          {{/each}}
        </div>
        <div class="venue-facilities-icons">
          {{#if @controller.model.venue.has_permanent_toilets}}🚻{{/if}}
          {{#if @controller.model.venue.has_portaloos}}🚽{{/if}}
          {{#if @controller.model.venue.has_bar}}🍺{{/if}}
          {{#if @controller.model.venue.has_showers}}🚿{{/if}}
          {{#if @controller.model.venue.has_power_supply}}⚡{{/if}}
          {{#if @controller.model.venue.has_water_supply}}💧{{/if}}
          {{#if @controller.model.venue.has_camping}}⛺{{/if}}
        </div>
      </div>
    {{/if}}

    {{#if @controller.model.topic_url}}
      <div class="event-discussion-cta">
        <DButton
          class="btn-primary btn-large"
          @href={{@controller.model.topic_url}}
          @label="discourse_event_system.event_detail.discussion_and_booking"
        />
      </div>
    {{/if}}

    {{!-- 3. Description --}}
    {{#if @controller.model.description_cooked}}
      <div class="event-description-box cooked">
        {{{@controller.model.description_cooked}}}
      </div>
    {{/if}}

    {{!-- Status banners --}}
    {{#if (eq @controller.model.status "cancelled")}}
      <div class="event-cancelled-banner">⚠️ This event has been cancelled.</div>
    {{else if @controller.bookingClosed}}
      <div class="event-closed-banner">⏰ Booking has closed for this event.</div>
    {{/if}}

    {{!-- 4. Pricing & Dates --}}
    {{#if @controller.model.pricing}}
      <div class="event-section-card">
        <h3>Pricing</h3>
        {{#if (eq @controller.model.pricing.rule_type "tiered")}}
          <p>First class: £{{@controller.model.pricing.first_class_price}}</p>
          <p>Additional classes: £{{@controller.model.pricing.subsequent_class_price}} each</p>
        {{else}}
          <p>£{{@controller.model.pricing.flat_price}} per class</p>
        {{/if}}
        <div class="event-booking-dates">
          {{#if @controller.model.booking_open}}
            <p class="booking-date-info">🟢 Bookings are open</p>
            {{#if @controller.model.topic_url}}
              <div class="event-discussion-cta">
                <DButton
                  class="btn-primary btn-large"
                  @href={{@controller.model.topic_url}}
                  @label="discourse_event_system.event_detail.discussion_and_booking"
                />
              </div>
            {{/if}}
          {{else if @controller.model.booking_manually_closed}}
            <p class="booking-date-info booking-closed">🔴 Bookings are closed</p>
          {{else if @controller.model.booking_opens_at}}
            <p class="booking-date-info">⏳ Bookings open soon</p>
          {{else}}
            <p class="booking-date-info booking-closed">🔴 Bookings are closed</p>
          {{/if}}
          {{#if @controller.model.refund_cutoff_days}}
            <p class="refund-info">💰 Refund cutoff: {{@controller.model.refund_cutoff_days}} days before event</p>
          {{else}}
            <p class="refund-info refund-ended">💰 No refunds available</p>
          {{/if}}
        </div>
      </div>
    {{/if}}

    {{!-- 5. Classes (read-only) --}}
    <div class="event-classes-readonly">
      <h2>Classes</h2>
      {{#each @controller.model.classes as |cls|}}
        <div class="event-class-row">
          <span class="event-class-name">{{cls.name}}</span>
          <span class="event-class-spaces field-help">{{cls.spaces_remaining}} / {{cls.capacity}} spaces</span>
        </div>
      {{/each}}
    </div>

    {{!-- 6. Actions --}}
    {{#if @controller.model.is_admin}}
      <LinkTo class="btn btn-default" @model={{@controller.model.id}} @route="event-manage">⚙️ Manage Event</LinkTo>
    {{/if}}

    {{!-- Discussion link --}}

    {{#if @controller.isChampionshipRound}}
      {{#if (eq @controller.results.status "published")}}
        <DesEventResults @results={{@controller.results}} />
      {{else}}
        <div class="event-results-section">
          <h2 class="results-heading">🏆 Championship Round Results</h2>
          {{#if (eq @controller.results.status "pending_match")}}
            <div class="results-awaiting"><p>⏳ Results being processed</p></div>
          {{else}}
            <div class="results-awaiting"><p>⏳ Awaiting event results</p></div>
          {{/if}}
        </div>
      {{/if}}
    {{/if}}

    {{!-- 7. Who's Coming (collapsible) --}}
    {{#if @controller.totalEntrantCount}}
      <div class="event-whos-coming">
        <button class="whos-coming-toggle" type="button" {{on "click" @controller.toggleWhosComingSection}}>
          <span class="whos-coming-chevron">{{if @controller.isWhosComingExpanded "▼" "▶"}}</span>
          <h2>👥 Who's Coming? ({{@controller.totalEntrantCount}} entries)</h2>
        </button>
        {{#if @controller.isWhosComingExpanded}}
          {{#each @controller.model.public_entrants as |cls|}}
            {{#if cls.entrants.length}}
              <div class="entrants-class">
                <h3>{{cls.name}}</h3>
                <table class="entrants-table entrants-table--public">
                  <thead>
                    <tr>
                      <th class="avatar-col"></th>
                      <th>Username</th>
                      {{#if @controller.model.is_admin}}<th>Full Name</th>{{/if}}
                      <th>Manufacturer</th>
                      <th>Model</th>
                      {{#if @controller.model.is_admin}}
                        <th>Transponder</th>
                        <th>BRCA No.</th>
                      {{/if}}
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {{#each cls.entrants as |entrant|}}
                      <tr class="entrant-row entrant-row--{{entrant.status}}">
                        <td class="avatar-col"><a data-user-card={{entrant.username}}><img alt="" class="entrant-avatar" src={{entrant.avatar_template}} /></a></td>
                        <td>{{entrant.username}}</td>
                        {{#if @controller.model.is_admin}}<td>{{entrant.name}}</td>{{/if}}
                        <td>{{entrant.manufacturer_name}}</td>
                        <td>{{entrant.model_name}}</td>
                        {{#if @controller.model.is_admin}}
                          <td class="transponder-number">{{entrant.transponder}}</td>
                          <td>{{entrant.brca_number}}</td>
                        {{/if}}
                        <td>
                          <span class="booking-status booking-status--{{entrant.status}}">
                            {{#if entrant.waitlist_position}}Waitlist #{{entrant.waitlist_position}}{{else}}{{entrant.status}}{{/if}}
                          </span>
                        </td>
                      </tr>
                    {{/each}}
                  </tbody>
                </table>
              </div>
            {{/if}}
          {{/each}}
        {{/if}}
      </div>
    {{/if}}

  </div>
  {{/if}}
</template>
