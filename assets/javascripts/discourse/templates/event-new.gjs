import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DEditor from "discourse/ui-kit/d-editor";

export default <template>
  <div class="event-new-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">📅 Events</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
    </div>

    <h1>Create New Event</h1>

    <div class="event-new-form">

      <div class="event-form-section">
        <h2>Basic Details</h2>

        <div class="org-form-field">
          <label>Organisation *</label>
          <select {{on "change" (fn @controller.updateField "organisation_id")}}>
            <option value="">Select organisation...</option>
            {{#each @controller.model.organisations as |org|}}
              <option value={{org.id}}>{{org.name}}</option>
            {{/each}}
          </select>
        </div>

        <div class="org-form-row">
          <div class="org-form-field">
            <label>Event Title *</label>
            <input
              placeholder="e.g. Summer RC Championship 2026"
              type="text"
              value={{@controller.eventTitle}}
              {{on "input" @controller.updateTitle}}
            />
          </div>
          <div class="org-form-field">
            <label>Event Type *</label>
            <select {{on "change" (fn @controller.updateField "event_type_id")}}>
              <option value="">Select type...</option>
              {{#each @controller.model.event_types as |et|}}
                <option value={{et.id}}>{{et.name}}</option>
              {{/each}}
            </select>
          </div>
        </div>
        <div class="event-description-field org-form-field">
          <label>Description</label>
          <DEditor
            @placeholder="Tell racers about this event..."
            @processPreview={{false}}
            @value={{@controller.description}}
          />
        </div>
        <div class="org-form-field">
          <label>Venue</label>
          <select {{on "change" (fn @controller.updateField "venue_id")}}>
            <option value="">No venue selected</option>
            {{#if @controller.clubVenues.length}}
              <optgroup label="Your Club's Venues">
                {{#each @controller.clubVenues as |venue|}}
                  <option value={{venue.id}}>{{venue.name}}</option>
                {{/each}}
              </optgroup>
            {{/if}}
            {{#if @controller.sharedVenues.length}}
              <optgroup label="Shared Venues">
                {{#each @controller.sharedVenues as |venue|}}
                  <option value={{venue.id}}>{{venue.name}}</option>
                {{/each}}
              </optgroup>
            {{/if}}
            {{#if @controller.otherVenues.length}}
              <optgroup label="Other Venues">
                {{#each @controller.otherVenues as |venue|}}
                  <option value={{venue.id}}>{{venue.name}}</option>
                {{/each}}
              </optgroup>
            {{/if}}
          </select>
        </div>
        <div class="org-form-row">
          <div class="org-form-field">
            <label>Start Date & Time *</label>
            <input
              type="datetime-local"
              {{on "change" (fn @controller.updateField "start_date")}}
            />
          </div>
          <div class="org-form-field">
            <label>End Date & Time</label>
            <input
              type="datetime-local"
              {{on "change" (fn @controller.updateField "end_date")}}
            />
          </div>
        </div>

        <div class="org-form-field">
          <label>Booking Method *</label>
          <select {{on "change" (fn @controller.updateField "booking_type")}}>
            <option value="internal">Online via this system (PayPal)</option>
            <option value="external">Booked externally</option>
          </select>
        </div>

        {{#if @controller.isExternalBooking}}
          <div class="org-form-field">
            <label>External Booking URL</label>
            <input
              placeholder="https://brca.org/book..."
              type="url"
              {{on "input" (fn @controller.updateField "external_booking_url")}}
            />
          </div>
          <div class="org-form-field">
            <label>Booking Details</label>
            <textarea
              placeholder="e.g. Book via BRCA website. Enter class and transponder number on the entry form."
              {{on "input" (fn @controller.updateField "external_booking_details")}}
            ></textarea>
          </div>
        {{else}}
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
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Refund Cutoff (days before event)</label>
              <input
                min="0"
                type="number"
                value="7"
                {{on "input" (fn @controller.updateField "refund_cutoff_days")}}
              />
            </div>
            <div class="org-form-field">
              <label>Max Classes Per Booking</label>
              <input
                min="1"
                placeholder="Leave blank for unlimited"
                type="number"
                {{on "input" (fn @controller.updateField "max_classes_per_booking")}}
              />
              <p class="field-help">Limit how many classes a user can book in one booking. Leave blank for unlimited.</p>
            </div>
          </div>
        {{/if}}

        {{!-- Discounts --}}
        <div class="org-form-section">
          <h3>Discounts <span class="field-help">(optional - flat rate deductions)</span></h3>
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Member - 1st Class Discount (£)</label>
              <input min="0" placeholder="0" step="0.50" type="number"
                {{on "input" (fn @controller.updatePricing "member_first_class_discount")}} />
            </div>
            <div class="org-form-field">
              <label>Member - Subsequent Classes (£)</label>
              <input min="0" placeholder="0" step="0.50" type="number"
                {{on "input" (fn @controller.updatePricing "member_subsequent_discount")}} />
            </div>
          </div>
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Junior (U16) - 1st Class Discount (£)</label>
              <input min="0" placeholder="0" step="0.50" type="number"
                {{on "input" (fn @controller.updatePricing "junior_first_class_discount")}} />
            </div>
            <div class="org-form-field">
              <label>Junior (U16) - Subsequent Classes (£)</label>
              <input min="0" placeholder="0" step="0.50" type="number"
                {{on "input" (fn @controller.updatePricing "junior_subsequent_discount")}} />
            </div>
          </div>
        </div>
      </div>

      {{!-- Classes --}}
      <div class="event-form-section">
        <div class="org-section-header">
          <h2>Classes</h2>
          <button class="btn btn-small btn-primary" {{on "click" @controller.addClass}}>
            + Add Class
          </button>
        </div>

        {{#if @controller.classes.length}}
          <div class="classes-list">
            {{#each @controller.classes as |cls index|}}
              <div class="class-row">
                <div class="org-form-field">
                  <label>Class Type</label>
                  <select value={{cls.class_type_id}} {{on "change" (fn @controller.updateClass index "class_type_id")}}>
                    <option value="">Select class...</option>
                    <option value="">Select class type...</option>
                    <optgroup label="Global Classes">
                    {{#each @controller.globalClassTypes as |ct|}}
                      <option selected={{eq (concat ct.id "") cls.class_type_id}} value={{ct.id}}>{{ct.name}}</option>
                    {{/each}}
                    </optgroup>
                    {{#if @controller.orgClassTypes.length}}
                      <optgroup label="Organisation Classes">
                      {{#each @controller.orgClassTypes as |ct|}}
                        <option selected={{eq (concat ct.id "") cls.class_type_id}} value={{ct.id}}>{{ct.name}}</option>
                      {{/each}}
                      </optgroup>
                    {{/if}}
                  </select>
                </div>
                <div class="org-form-field">
                  <label>Capacity</label>
                  <input
                    min="1"
                    type="number"
                    value={{cls.capacity}}
                    {{on "input" (fn @controller.updateClass index "capacity")}}
                  />
                </div>
                <button
                  class="btn btn-small btn-danger remove-class-btn"
                  {{on "click" (fn @controller.removeClass index)}}
                >
                  ✕
                </button>
              </div>
            {{/each}}
          </div>
        {{else}}
          <p class="field-help">No classes added yet. Click "+ Add Class" to add one.</p>
        {{/if}}
      </div>

      {{!-- Pricing - only for internal bookings --}}
      {{#unless @controller.isExternalBooking}}
        <div class="event-form-section">
          <h2>Pricing</h2>

          <div class="org-form-field">
            <label>Pricing Type</label>
            <select {{on "change" @controller.updatePricingType}}>
              <option value="tiered">Tiered (different price for first class)</option>
              <option value="flat">Flat (same price per class)</option>
            </select>
          </div>

          {{#if @controller.pricingIsFlat}}
            <div class="org-form-field">
              <label>Price per class (£)</label>
              <input
                min="0"
                placeholder="e.g. 20"
                step="0.01"
                type="number"
                {{on "input" (fn @controller.updatePricing "flat_price")}}
              />
            </div>
          {{else}}
            <div class="org-form-row">
              <div class="org-form-field">
                <label>First Class Price (£)</label>
                <input
                  min="0"
                  placeholder="e.g. 20"
                  step="0.01"
                  type="number"
                  {{on "input" (fn @controller.updatePricing "first_class_price")}}
                />
              </div>
              <div class="org-form-field">
                <label>Additional Classes Price (£)</label>
                <input
                  min="0"
                  placeholder="e.g. 10"
                  step="0.01"
                  type="number"
                  {{on "input" (fn @controller.updatePricing "subsequent_class_price")}}
                />
              </div>
            </div>
          {{/if}}
        </div>
      {{/unless}}

      <div class="event-form-actions">
        <button
          class="btn btn-primary"
          disabled={{@controller.isSaving}}
          {{on "click" @controller.saveEvent}}
        >
          {{if @controller.isSaving "Saving..." "Save as Draft"}}
        </button>
        <LinkTo class="btn btn-default" @route="events">Cancel</LinkTo>
      </div>
    </div>
  </div>
</template>
