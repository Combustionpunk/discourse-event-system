import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";

export default <template>
  <div class="organisation-new-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="events">📅 Events</LinkTo>
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
    </div>

    <h1>Create Organisation</h1>
    <p class="org-new-intro">
      Submit your organisation for review. An administrator will approve it before it appears publicly.
    </p>

    {{#if @controller.successMessage}}
      <div class="alert alert-success">
        {{@controller.successMessage}}
      </div>
    {{else}}
      <form class="org-form">
        <div class="org-form-field">
          <label>Organisation Name *</label>
          <input
            placeholder="e.g. Midlands RC Racing Club"
            type="text"
            value={{@controller.model.name}}
            {{on "input" (fn @controller.updateField "name")}}
          />
        </div>

        <div class="org-form-field">
          <label>Description</label>
          <textarea
            placeholder="Tell us about your organisation..."
            {{on "input" (fn @controller.updateField "description")}}
          >{{@controller.model.description}}</textarea>
        </div>

        <div class="org-form-row">
          <div class="org-form-field">
            <label>Email</label>
            <input
              placeholder="contact@yourclub.com"
              type="email"
              value={{@controller.model.email}}
              {{on "input" (fn @controller.updateField "email")}}
            />
          </div>
          <div class="org-form-field">
            <label>Phone</label>
            <input
              placeholder="07700 900000"
              type="tel"
              value={{@controller.model.phone}}
              {{on "input" (fn @controller.updateField "phone")}}
            />
          </div>
        </div>

        <div class="org-form-field">
          <label>Website</label>
          <input
            placeholder="https://www.yourclub.com"
            type="url"
            value={{@controller.model.website}}
            {{on "input" (fn @controller.updateField "website")}}
          />
        </div>

        <div class="org-form-field">
          <label>Address</label>
          <textarea
            placeholder="Your club's address..."
            {{on "input" (fn @controller.updateField "address")}}
          >{{@controller.model.address}}</textarea>
        </div>

        <div class="org-form-field">
          <label>Google Maps URL</label>
          <input
            placeholder="https://maps.google.com/..."
            type="url"
            value={{@controller.model.google_maps_url}}
            {{on "input" (fn @controller.updateField "google_maps_url")}}
          />
        </div>

        <div class="org-form-field">
          <label>PayPal Email</label>
          <input
            placeholder="payments@yourclub.com"
            type="email"
            value={{@controller.model.paypal_email}}
            {{on "input" (fn @controller.updateField "paypal_email")}}
          />
        </div>

        <div class="org-form-actions">
          <button
            class="btn btn-primary"
            disabled={{@controller.isSaving}}
            {{on "click" @controller.saveOrganisation}}
          >
            {{if @controller.isSaving "Submitting..." "Submit for Approval"}}
          </button>
          <LinkTo class="btn btn-default" @route="organisations">
            Cancel
          </LinkTo>
        </div>
      </form>
    {{/if}}
  </div>
</template>
