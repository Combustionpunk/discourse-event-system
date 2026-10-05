import { concat, fn, get } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq, or } from "discourse/truth-helpers";
import DEditor from "discourse/ui-kit/d-editor";
import { i18n } from "discourse-i18n";
import DesCloneEventModal from "../components/des-clone-event-modal";

export default <template>
  <div class="event-manage-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">{{i18n "discourse_event_system.nav.event_admin"}}</LinkTo>
      <LinkTo class="btn btn-default" @model={{@controller.model.event.id}} @route="event">
        👁 View Event
      </LinkTo>
    </div>

    <div class="event-manage-header">
      <div>
        <h1>⚙️ {{@controller.model.event.title}}</h1>
        <span class="event-status event-status--{{@controller.model.event.status}}">
          {{@controller.model.event.status}}
        </span>
      </div>
      <div class="event-manage-actions">
        {{#if (eq @controller.model.event.status "draft")}}
          <button class="btn btn-warning" {{on "click" @controller.publishEvent}}>
            📢 Publish
          </button>
        {{/if}}
        {{#unless (eq @controller.model.event.status "cancelled")}}
          <button class="btn btn-danger" {{on "click" @controller.cancelEvent}}>
            ❌ Cancel Event
          </button>
        {{/unless}}
        <button class="btn btn-default" {{on "click" @controller.cloneEvent}}>📋 Clone Event</button>
      </div>
    </div>

    {{!-- Tabs --}}
    <div class="manage-tabs">
      <button
        class="manage-tab {{if (eq @controller.activeTab 'details') 'active'}}"
        {{on "click" @controller.showDetails}}
      >
        📋 Details
      </button>
      <button
        class="manage-tab {{if (eq @controller.activeTab 'entrants') 'active'}}"
        {{on "click" @controller.showEntrants}}
      >
        🏎️ Entrants
      </button>
      <button
        class="manage-tab {{if (eq @controller.activeTab 'classes') 'active'}}"
        {{on "click" @controller.showClasses}}
      >
        🏁 Classes
      </button>
      <button
        class="manage-tab {{if (eq @controller.activeTab 'pricing') 'active'}}"
        {{on "click" @controller.showPricing}}
      >
        💷 Pricing & Discounts
      </button>
      <button
        class="manage-tab {{if (eq @controller.activeTab 'payout') 'active'}}"
        {{on "click" (fn @controller.setTab "payout")}}
      >
        💰 Payout
      </button>
      <button
        class="manage-tab {{if (eq @controller.activeTab 'results') 'active'}}"
        {{on "click" (fn @controller.setTab "results")}}
      >
        🏆 Results
      </button>
    </div>

    {{!-- Details Tab --}}
    {{#if (eq @controller.activeTab "details")}}
      <div class="manage-section">
        <div class="manage-section-header">
          <h2>Event Details</h2>
          <button class="btn btn-small btn-default" {{on "click" @controller.toggleEdit}}>
            {{if @controller.editMode "Cancel" "✏️ Edit"}}
          </button>
        </div>

        {{#if @controller.editMode}}
          <div class="org-form-field">
            <label>Title</label>
            <input type="text" value={{@controller.model.event.title}} {{on "input" (fn @controller.updateField "title")}} />
          </div>
          <div class="event-description-field org-form-field">
            <label>Description</label>
            <DEditor @processPreview={{false}} @value={{@controller.editDescription}} />
          </div>
          <div class="org-form-field">
            <label>Venue</label>
            <select {{on "change" (fn @controller.updateField "venue_id")}}>
              <option value="">No venue selected</option>
              {{#each @controller.model.venues as |venue|}}
                <option selected={{eq (concat venue.id "") (concat @controller.model.event.venue_id "")}} value={{venue.id}}>{{venue.name}}</option>
              {{/each}}
            </select>
          </div>
          <div class="org-form-field">
            <label>Event Type</label>
            <select {{on "change" @controller.updateEventType}}>
              {{#each @controller.model.event_types as |et|}}
                <option selected={{eq (concat @controller.editEventTypeId "") (concat et.id "")}} value={{et.id}}>{{et.name}}</option>
              {{/each}}
            </select>
          </div>
          <div class="org-form-field">
            <label>RC Results Meeting ID</label>
            <input placeholder="e.g. 19668" type="number" value={{@controller.editRcResultsMeetingId}} {{on "input" (fn @controller.updateField "editRcResultsMeetingId")}} />
          </div>
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Start Date</label>
              <input type="datetime-local" value={{@controller.model.event.start_date}} {{on "change" (fn @controller.updateField "start_date")}} />
            </div>
            <div class="org-form-field">
              <label>End Date</label>
              <input type="datetime-local" value={{@controller.model.event.end_date}} {{on "change" (fn @controller.updateField "end_date")}} />
            </div>
          </div>
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Bookings Open</label>
              <select {{on "change" @controller.updateBookingOpens}}>
                <option selected={{eq @controller.bookingOpensDaysBefore ""}} value="">Immediately on creation</option>
                <option selected={{eq @controller.bookingOpensDaysBefore "7"}} value="7">1 week before event</option>
                <option selected={{eq @controller.bookingOpensDaysBefore "14"}} value="14">2 weeks before event</option>
                <option selected={{eq @controller.bookingOpensDaysBefore "21"}} value="21">3 weeks before event</option>
                <option selected={{eq @controller.bookingOpensDaysBefore "28"}} value="28">4 weeks before event</option>
                <option selected={{eq @controller.bookingOpensDaysBefore "42"}} value="42">6 weeks before event</option>
                <option selected={{eq @controller.bookingOpensDaysBefore "56"}} value="56">8 weeks before event</option>
              </select>
            </div>
            <div class="org-form-field">
              <label>Bookings Close</label>
              <select {{on "change" @controller.updateBookingCloses}}>
                <option selected={{eq @controller.bookingClosesDaysBefore ""}} value="">On event day</option>
                <option selected={{eq @controller.bookingClosesDaysBefore "1"}} value="1">1 day before event</option>
                <option selected={{eq @controller.bookingClosesDaysBefore "2"}} value="2">2 days before event</option>
                <option selected={{eq @controller.bookingClosesDaysBefore "3"}} value="3">3 days before event</option>
                <option selected={{eq @controller.bookingClosesDaysBefore "7"}} value="7">1 week before event</option>
                <option selected={{eq @controller.bookingClosesDaysBefore "14"}} value="14">2 weeks before event</option>
              </select>
            </div>
          </div>
          <div class="org-form-field">
            <label>Max Classes Per Booking</label>
            <input min="1" placeholder="Unlimited" type="number" value={{@controller.model.event.max_classes_per_booking}} {{on "input" (fn @controller.updateField "max_classes_per_booking")}} />
            <p class="field-help">Leave blank for unlimited.</p>
          </div>
          <button
            class="btn btn-primary"
            disabled={{@controller.isSaving}}
            {{on "click" @controller.saveChanges}}
          >
            {{if @controller.isSaving "Saving..." "Save Changes"}}
          </button>
        {{else}}
          <div class="event-detail-list">
            <div class="event-detail-row">
              <span class="event-detail-label">📅 Start</span>
              <span>{{@controller.model.event.formatted_start_date}}</span>
            </div>
            {{#if @controller.model.event.location}}
              <div class="event-detail-row">
                <span class="event-detail-label">📍 Location</span>
                <span>{{@controller.model.event.location}}</span>
              </div>
            {{/if}}
            {{#if @controller.model.event.booking_closing_date}}
              <div class="event-detail-row">
                <span class="event-detail-label">⏰ Booking closes</span>
                <span>{{@controller.model.event.formatted_booking_closing_date}}</span>
              </div>
            {{/if}}
          </div>
        {{/if}}

        <div class="manage-section" style="margin-bottom:16px;">
          <h3>Booking Status</h3>
          <p class="field-help">
            {{#if @controller.model.event.booking_manually_closed}}
              🔴 Bookings manually closed
            {{else if @controller.model.event.booking_manually_open}}
              🟢 Bookings manually opened
            {{else if @controller.model.event.booking_open}}
              🟢 Bookings open
              {{#if @controller.model.event.booking_closes_at}}
                — closes {{@controller.model.event.booking_closes_at}}
              {{/if}}
            {{else}}
              🔴 Bookings closed
              {{#if @controller.model.event.booking_opens_at}}
                — opens {{@controller.model.event.booking_opens_at}}
              {{/if}}
            {{/if}}
          </p>
          <div style="display:flex;gap:8px;">
            {{#if @controller.model.event.booking_manually_closed}}
              <button class="btn btn-primary" {{on "click" @controller.reopenBookings}}>🟢 Re-open Bookings</button>
            {{else}}
              <button class="btn btn-danger" {{on "click" @controller.closeBookings}}>🔴 Close Bookings</button>
            {{/if}}
            {{#if @controller.model.event.booking_manually_open}}
              <button class="btn btn-default" {{on "click" @controller.clearManualBookingOverride}}>Clear Manual Override</button>
            {{else}}
              <button class="btn btn-default" {{on "click" @controller.forceOpenBookings}}>🟢 Force Open Bookings</button>
            {{/if}}
          </div>
        </div>

        <div class="manage-classes">
          <h3>Classes</h3>
          {{#each @controller.model.event.classes as |cls|}}
            <div class="manage-class-row">
              <span class="manage-class-name">{{cls.name}}</span>
              <span class="manage-class-bookings">{{cls.bookings_count}} / {{cls.capacity}} booked</span>
              <span class="org-status org-status--{{cls.status}}">{{cls.status}}</span>
            </div>
          {{/each}}
        </div>
      </div>
    {{/if}}

    {{!-- Classes Tab --}}
    {{#if (eq @controller.activeTab "classes")}}
      <div class="manage-section">
        <h2>Classes</h2>

        <table class="entrants-table">
          <thead>
            <tr>
              <th>Class Name</th>
              <th>Capacity</th>
              <th>Spaces Remaining</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {{#each @controller.model.event.classes as |cls|}}
              <tr>
                <td>{{cls.name}}</td>
                <td>
                  {{#if (eq @controller.editingClassId cls.id)}}
                    <input
                      class="inline-edit-input"
                      min="1"
                      type="number"
                      value={{@controller.editingClassCapacity}}
                      {{on "input" @controller.updateEditingCapacity}}
                    />
                  {{else}}
                    {{cls.capacity}}
                  {{/if}}
                </td>
                <td>{{cls.spaces_remaining}}</td>
                <td>
                  <span class="org-status org-status--{{cls.status}}">{{cls.status}}</span>
                </td>
                <td>
                  {{#if (eq @controller.editingClassId cls.id)}}
                    <button class="btn btn-small btn-primary" {{on "click" (fn @controller.saveClassCapacity cls)}}>
                      Save
                    </button>
                    <button class="btn btn-small btn-default" {{on "click" @controller.cancelEditClass}}>
                      Cancel
                    </button>
                  {{else}}
                    <button class="btn btn-small btn-default" {{on "click" (fn @controller.startEditClass cls)}}>
                      Edit Capacity
                    </button>
                    {{#if (eq cls.status "inactive")}}
                      <button class="btn btn-small btn-primary" {{on "click" (fn @controller.toggleClassStatus cls)}}>
                        Reopen
                      </button>
                    {{else}}
                      <button class="btn btn-small btn-danger" {{on "click" (fn @controller.toggleClassStatus cls)}}>
                        Close
                      </button>
                    {{/if}}
                    <button class="btn btn-small btn-danger" {{on "click" (fn @controller.deleteClass cls)}}>
                      🗑 Delete
                    </button>
                  {{/if}}
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>

        <h3>Add Class</h3>
        {{#if @controller.classTypes}}
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Class Type</label>
              <select {{on "change" @controller.updateNewClassTypeId}}>
                {{#each @controller.classTypes as |ct|}}
                  <option selected={{eq ct.id @controller.newClassTypeId}} value={{ct.id}}>{{ct.name}}</option>
                {{/each}}
              </select>
            </div>
            <div class="org-form-field">
              <label>Capacity</label>
              <input
                min="1"
                placeholder="e.g. 20"
                type="number"
                value={{@controller.newClassCapacity}}
                {{on "input" @controller.updateNewClassCapacity}}
              />
            </div>
            <div class="org-form-field" style="align-self: flex-end;">
              <button class="btn btn-primary" {{on "click" @controller.addClass}}>
                Add Class
              </button>
            </div>
          </div>
        {{else}}
          <p class="field-help">Loading class types...</p>
        {{/if}}
      </div>
    {{/if}}

    {{!-- Entrants Tab --}}
    {{#if (eq @controller.activeTab "entrants")}}
      <div class="manage-section">
        <div class="manage-section-header">
          <h2>Entrants</h2>
          <button class="btn btn-default" {{on "click" @controller.downloadCsv}}>
            📥 Download RCTiming CSV
          </button>
          <button class="btn btn-default" {{on "click" @controller.syncTransponders}}>
            🔄 Sync Transponders
          </button>
        </div>

        <div class="entrants-filters">
          <button class="btn btn-small {{if (eq @controller.entrantsFilter 'all') 'btn-primary' 'btn-default'}}"
            {{on "click" (fn @controller.setEntrantsFilter "all")}}>
            All ({{@controller.entrantsStatusCounts.all}})
          </button>
          <button class="btn btn-small {{if (eq @controller.entrantsFilter 'confirmed') 'btn-primary' 'btn-default'}}"
            {{on "click" (fn @controller.setEntrantsFilter "confirmed")}}>
            ✅ Confirmed ({{@controller.entrantsStatusCounts.confirmed}})
          </button>
          <button class="btn btn-small {{if (eq @controller.entrantsFilter 'pending') 'btn-primary' 'btn-default'}}"
            {{on "click" (fn @controller.setEntrantsFilter "pending")}}>
            ⏳ Pending ({{@controller.entrantsStatusCounts.pending}})
          </button>
          <button class="btn btn-small {{if (eq @controller.entrantsFilter 'cancelled') 'btn-primary' 'btn-default'}}"
            {{on "click" (fn @controller.setEntrantsFilter "cancelled")}}>
            ❌ Cancelled ({{@controller.entrantsStatusCounts.cancelled}})
          </button>
          <button class="btn btn-small {{if (eq @controller.entrantsFilter 'waitlist') 'btn-primary' 'btn-default'}}"
            {{on "click" (fn @controller.setEntrantsFilter "waitlist")}}>
            📋 Waitlist ({{@controller.entrantsStatusCounts.waitlist}})
          </button>
        </div>

        {{#each @controller.filteredEntrantsClasses as |cls|}}
          <div class="entrants-class">
            <h3>
              {{cls.name}}
              <span class="field-help">{{cls.entrants.length}} / {{cls.capacity}} entries</span>
            </h3>
            {{#if cls.entrants.length}}
              <table class="entrants-table">
                <thead>
                  <tr>
                    <th class="avatar-col"></th>
                    <th>Username</th>
                    <th>Manufacturer</th>
                    <th>Model</th>
                    <th>Transponder</th>
                    <th>BRCA No.</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {{#each cls.entrants as |entrant|}}
                    <tr class="entrant-row entrant-row--{{entrant.status}}">
                      <td class="avatar-col"><a data-user-card={{entrant.username}}><img alt="" class="entrant-avatar" src={{entrant.avatar_template}} /></a></td>
                      <td>{{entrant.username}}</td>
                      <td>{{entrant.manufacturer_name}}</td>
                      <td>{{entrant.model_name}}</td>
                      <td class="transponder-number">{{entrant.transponder}}</td>
                      <td>{{entrant.brca_number}}</td>
                      <td>
                        <span class="booking-status booking-status--{{entrant.status}}">
                          {{#if entrant.waitlist_position}}Waitlist #{{entrant.waitlist_position}}{{else}}{{entrant.status}}{{/if}}
                        </span>
                      </td>
                      <td class="entrant-actions">
                        {{#if (eq entrant.status "waitlist")}}
                          <button class="btn btn-small btn-danger" {{on "click" (fn @controller.removeFromWaitlist entrant)}}>
                            Remove from Waitlist
                          </button>
                        {{else}}
                          {{#unless (eq entrant.status "cancelled")}}
                            <button class="btn btn-small btn-danger" {{on "click" (fn @controller.cancelEntrant entrant cls.name)}}>Cancel</button>
                          {{/unless}}
                          {{#if @controller.currentUser.admin}}
                            <button class="btn btn-small btn-danger" {{on "click" (fn @controller.deleteBooking entrant cls.name)}}>🗑 Delete</button>
                          {{/if}}
                          {{#unless (eq entrant.status "cancelled")}}
                            <button class="btn btn-small btn-default" {{on "click" (fn @controller.startSwapCar entrant entrant.event_class_id)}}>🔄</button>
                            <button class="btn btn-small btn-default" {{on "click" (fn @controller.startMoveClass entrant cls.id)}}>↔️</button>
                          {{/unless}}
                        {{/if}}
                      </td>
                    </tr>
                  {{/each}}
                </tbody>
              </table>
            {{else}}
              <p class="field-help">No entrants matching filter.</p>
            {{/if}}
          </div>
        {{/each}}
      </div>
    {{/if}}

    {{#if @controller.swapCarEntrant}}
      <div class="car-selection-overlay">
        <div class="car-selection-modal">
          <h2>🔄 Change Car for {{@controller.swapCarEntrant.username}}</h2>
          {{#if @controller.swapCarOptions.length}}
            {{#each @controller.swapCarOptions as |car|}}
              <div class="family-search-result" role="button" {{on "click" (fn @controller.confirmSwapCar car.id)}}>
                <strong>{{car.friendly_name}}</strong> — {{car.driveline}} — {{car.transponder_number}}
                {{#if car.owner_username}} <span class="field-help">({{car.owner_username}})</span>{{/if}}
              </div>
            {{/each}}
          {{else}}
            <p class="field-help">No eligible cars found.</p>
          {{/if}}
          <button class="btn btn-default" style="margin-top:12px;" {{on "click" @controller.cancelSwapCar}}>Cancel</button>
        </div>
      </div>
    {{/if}}


    {{#if @controller.moveClassEntrant}}
      <div class="car-selection-overlay">
        <div class="car-selection-modal">
          <h2>↔️ Move {{@controller.moveClassEntrant.username}} to another class</h2>
          {{#if @controller.moveClassOptions.length}}
            {{#each @controller.moveClassOptions as |cls|}}
              <div class="family-search-result" role="button" {{on "click" (fn @controller.confirmMoveClass cls.id)}}>
                <strong>{{cls.name}}</strong> <span class="field-help">({{cls.spaces}} spaces remaining)</span>
              </div>
            {{/each}}
          {{else}}
            <p class="field-help">No other classes with available spaces.</p>
          {{/if}}
          <button class="btn btn-default" style="margin-top:12px;" {{on "click" @controller.cancelMoveClass}}>Cancel</button>
        </div>
      </div>
    {{/if}}


    {{!-- Pricing Tab --}}
    {{#if (eq @controller.activeTab "pricing")}}
      <div class="manage-section">
        <h2>Pricing & Discounts</h2>
        <div class="org-form-row">
          <div class="org-form-field">
            <label>First Class Price (£)</label>
            <input min="0" step="0.50" type="number"
              value={{@controller.pricingForm.first_class_price}}
              {{on "input" (fn @controller.updatePricingForm "first_class_price")}} />
          </div>
          <div class="org-form-field">
            <label>Subsequent Classes (£)</label>
            <input min="0" step="0.50" type="number"
              value={{@controller.pricingForm.subsequent_class_price}}
              {{on "input" (fn @controller.updatePricingForm "subsequent_class_price")}} />
          </div>
        </div>
        <h3>Member Discounts</h3>
        <div class="org-form-row">
          <div class="org-form-field">
            <label>Member - 1st Class Discount (£)</label>
            <input min="0" step="0.50" type="number"
              value={{@controller.pricingForm.member_first_class_discount}}
              {{on "input" (fn @controller.updatePricingForm "member_first_class_discount")}} />
          </div>
          <div class="org-form-field">
            <label>Member - Subsequent Classes (£)</label>
            <input min="0" step="0.50" type="number"
              value={{@controller.pricingForm.member_subsequent_discount}}
              {{on "input" (fn @controller.updatePricingForm "member_subsequent_discount")}} />
          </div>
        </div>
        <h3>Junior Discounts (Under 16)</h3>
        <div class="org-form-row">
          <div class="org-form-field">
            <label>Junior - 1st Class Discount (£)</label>
            <input min="0" step="0.50" type="number"
              value={{@controller.pricingForm.junior_first_class_discount}}
              {{on "input" (fn @controller.updatePricingForm "junior_first_class_discount")}} />
          </div>
          <div class="org-form-field">
            <label>Junior - Subsequent Classes (£)</label>
            <input min="0" step="0.50" type="number"
              value={{@controller.pricingForm.junior_subsequent_discount}}
              {{on "input" (fn @controller.updatePricingForm "junior_subsequent_discount")}} />
          </div>
        </div>
        <button class="btn btn-primary" {{on "click" @controller.savePricing}}>
          💾 Save Pricing
        </button>
      </div>
    {{/if}}

    {{#if (eq @controller.activeTab "results")}}
      <div class="manage-section">
        <div class="manage-section-header">
          <h3>Race Results</h3>
        </div>

        {{#if @controller.isLoadingResults}}
          <p>Loading results...</p>
        {{else if (eq @controller.results.status "none")}}
          <div class="results-empty">
            {{#if @controller.model.event.rc_results_meeting_id}}
              <p>No results imported yet for this event.</p>
              <button class="btn btn-primary" disabled={{@controller.isImporting}} {{on "click" @controller.importResults}}>
                {{if @controller.isImporting "Importing..." "📥 Import Results from RC Results"}}
              </button>
            {{else}}
              <p>⚠️ No RC Results Meeting ID set on this event. Please add one in the Details tab before importing results.</p>
            {{/if}}
          </div>
        {{else if (eq @controller.results.status "pending_match")}}
          <div class="results-matching">
            <p>✅ Results imported. Please review driver matches below, then publish.</p>
            <button class="btn btn-default" disabled={{@controller.isImporting}} {{on "click" @controller.importResults}}>
              {{if @controller.isImporting "Importing..." "🔄 Re-import Results"}}
            </button>
            <button class="btn btn-primary" disabled={{@controller.isPublishing}} style="margin-left: 8px;" {{on "click" @controller.publishResults}}>
              {{if @controller.isPublishing "Publishing..." "🏆 Publish Results & Award Badges"}}
            </button>

            <h4 style="margin-top: 24px;">Driver Match Confirmation</h4>
            <p class="field-help">Auto-matched drivers are shown below. Unmatched drivers are highlighted — please assign them manually before publishing.</p>

            {{#each @controller.results.races as |race|}}
              <div class="match-race-section">
                <h5>{{race.race_name}}</h5>
                <table class="results-table">
                  <thead>
                    <tr>
                      <th>Pos</th>
                      <th>Car</th>
                      <th>RC Results Name</th>
                      <th>Matched User</th>
                      <th>Best Lap</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {{#each race.entries as |entry|}}
                      <tr class={{unless entry.user_id 'unmatched-entry'}}>
                        <td>{{entry.position}}</td>
                        <td>{{entry.car_number}}</td>
                        <td>{{entry.driver_name}}</td>
                        <td style="position:relative;">
                          <input
                            class="match-username-input"
                            placeholder="Type username..."
                            type="text"
                            value={{or (get @controller.pendingMatches entry.id) entry.user.username}}
                            {{on "input" (fn @controller.loadUserSuggestions entry.id)}}
                          />
                          {{#if (get @controller.userSuggestions entry.id)}}
                            <ul class="username-suggestions">
                              {{#each (get @controller.userSuggestions entry.id) as |suggestion|}}
                                <li {{on "click" (fn @controller.selectSuggestion entry.id suggestion)}}>
                                  <img height="20" src={{suggestion.avatar}} width="20" />
                                  {{suggestion.username}}
                                </li>
                              {{/each}}
                            </ul>
                          {{/if}}
                        </td>
                        <td>
                          {{#if entry.best_lap}}
                            {{#if entry.best_lap_rejected}}
                              <span class="lap-rejected">❌ {{entry.best_lap}}</span>
                              <button class="btn btn-small btn-default" {{on "click" (fn @controller.unrejectLap entry)}}>Restore</button>
                            {{else}}
                              <span>{{entry.best_lap}}</span>
                              <button class="btn btn-small btn-danger" {{on "click" (fn @controller.rejectLap entry)}}>❌ Reject</button>
                            {{/if}}
                          {{else}}
                            <span class="field-help">—</span>
                          {{/if}}
                        </td>
                        <td>
                          {{#if entry.user}}
                            <span class="match-status matched">✅ {{entry.user.username}}</span>
                          {{else}}
                            <span class="match-status unmatched">❓ Unmatched</span>
                          {{/if}}
                        </td>
                      </tr>
                    {{/each}}
                  </tbody>
                </table>
              </div>
            {{/each}}

            <button class="btn btn-default" disabled={{@controller.isSavingMatches}} {{on "click" @controller.saveMatches}}>
              {{if @controller.isSavingMatches "Saving..." "💾 Save Matches"}}
            </button>
          </div>
        {{else if (eq @controller.results.status "published")}}
          <div class="results-published">
            <p>✅ Results published and badges awarded.</p>
            <button class="btn btn-default" disabled={{@controller.isImporting}} {{on "click" @controller.importResults}}>
              {{if @controller.isImporting "Importing..." "🔄 Re-import Results"}}
            </button>
          </div>
        {{/if}}
      </div>
    {{/if}}

    {{!-- Payout Tab --}}
    {{#if (eq @controller.activeTab "payout")}}
      <div class="event-payout-tab">
        {{#if @controller.payoutLoading}}
          <p>Loading payout details...</p>
        {{else}}
          {{#if @controller.payoutData.payout}}
            <div class="payout-status-banner payout-status--{{@controller.payoutData.payout.status}}">
              Status: <strong>{{@controller.payoutData.payout.status}}</strong>
              {{#if @controller.payoutData.payout.approved_at}} — Approved {{@controller.payoutData.payout.approved_at}}{{/if}}
              {{#if @controller.payoutData.payout.paid_at}} — Paid {{@controller.payoutData.payout.paid_at}}{{/if}}
            </div>
          {{/if}}

          {{#if @controller.payoutCalc}}
            <div class="payout-breakdown">
              <h3>Payout Breakdown</h3>
              <table class="payout-table">
                <tr><td>Gross ({{@controller.payoutCalc.transaction_count}} bookings)</td><td class="payout-amount">£{{@controller.payoutCalc.gross_amount}}</td></tr>
                <tr><td>PayPal fees ({{@controller.payoutCalc.paypal_fee_percent}}% + £{{@controller.payoutCalc.paypal_fee_fixed}} × {{@controller.payoutCalc.transaction_count}})</td><td class="payout-amount payout-deduction">- £{{@controller.payoutCalc.paypal_fee_amount}}</td></tr>
                <tr><td>Surcharge ({{@controller.payoutCalc.surcharge_percent}}%)</td><td class="payout-amount payout-deduction">- £{{@controller.payoutCalc.surcharge_amount}}</td></tr>
                <tr class="payout-net"><td><strong>Net to Organisation</strong></td><td class="payout-amount"><strong>£{{@controller.payoutCalc.net_amount}}</strong></td></tr>
              </table>
              {{#if @controller.payoutCalc.complimentary_count}}
                <p class="field-help">+ {{@controller.payoutCalc.complimentary_count}} complimentary entries (excluded from calculation)</p>
              {{/if}}
            </div>
          {{/if}}

          {{#if @controller.currentUser.admin}}
            {{#if (eq @controller.payoutStatus "pending")}}
              <button class="btn btn-primary" disabled={{@controller.payoutActionLoading}} {{on "click" @controller.approvePayout}}>
                {{if @controller.payoutActionLoading "Processing..." "✅ Approve Payout"}}
              </button>
            {{/if}}

            {{#if (or (eq @controller.payoutStatus "pending") (eq @controller.payoutStatus "failed"))}}
              <div class="manual-payout-section" style="margin-top:16px;padding:12px;background:var(--primary-very-low);border-radius:8px;">
                <h4>Manual Payment</h4>
                <p class="field-help">Use this to record a manual bank transfer or cash payment.</p>
                <div class="org-form-field">
                  <label>Notes (optional)</label>
                  <input placeholder="e.g. Bank transfer ref: 12345" type="text" value={{@controller.manualPayoutNotes}} {{on "input" @controller.updateManualPayoutNotes}} />
                </div>
                <button class="btn btn-success" {{on "click" @controller.markPayoutManuallyPaid}}>
                  ✅ Mark as Manually Paid
                </button>
              </div>
            {{/if}}
          {{/if}}

          {{#if (eq @controller.payoutStatus "approved")}}
            <div class="payout-approved-banner">
              ✅ Payout approved — organisation can now claim
            </div>
          {{/if}}

          {{#if @controller.payoutError}}
            <p class="payout-error">{{@controller.payoutError}}</p>
          {{/if}}
        {{/if}}
      </div>
    {{/if}}

    {{#if @controller.showCloneModal}}
      <DesCloneEventModal
        @onClose={{@controller.closeCloneModal}}
        @onSave={{@controller.confirmCloneEvent}}
        @originalTitle={{@controller.model.event.title}}
      />
    {{/if}}

  </div>
</template>
