import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";
import DesClassTypeForm from "../components/des-class-type-form";
import DesEventLink from "../components/des-event-link";
import DesMeetingsLink from "../components/des-meetings-link";

export default <template>
  <div class="organisation-container">
    <div class="events-nav">
      <DesMeetingsLink class="btn btn-default" />
      <LinkTo class="btn btn-default" @route="organisations">🏢 Organisations</LinkTo>
    </div>

    <div class="org-detail-header">
      <div>
        {{#if @controller.model.logo_url}}
          <img alt="" class="org-logo org-logo--large" src={{@controller.model.logo_url}} />
        {{/if}}
        <h1>{{@controller.model.name}}</h1>
        <span class="org-status org-status--{{@controller.model.status}}">{{@controller.model.status}}</span>
      </div>
    </div>

    {{#if @controller.model.description}}
      <p class="org-detail-description">{{@controller.model.description}}</p>
    {{/if}}

    {{!-- Tabs for org admins --}}
    <div class="manage-tabs">
        <button class="manage-tab {{if (eq @controller.activeTab 'details') 'active'}}" {{on "click" @controller.showDetails}}>
          📋 Details
        </button>
        <button class="manage-tab {{if (eq @controller.activeTab 'venues') 'active'}}" {{on "click" (fn @controller.showTab "venues")}}>
          📍 Venues
        </button>
        {{#if @controller.model.is_admin}}
        <button class="manage-tab {{if (eq @controller.activeTab 'memberships') 'active'}}" {{on "click" @controller.showMemberships}}>
          🎫 Memberships
        </button>
        {{/if}}
        {{#if @controller.model.is_admin}}
          <button class="manage-tab {{if (eq @controller.activeTab 'members') 'active'}}" {{on "click" @controller.showMembers}}>
            👥 Members
          </button>
          <button class="manage-tab {{if (eq @controller.activeTab 'events') 'active'}}" {{on "click" @controller.showEvents}}>
            📅 Events
          </button>
          <button class="manage-tab {{if (eq @controller.activeTab 'rules') 'active'}}" {{on "click" @controller.showRules}}>
            ⚙️ Class Rules
          </button>
          <button class="manage-tab {{if (eq @controller.activeTab 'settings') 'active'}}" {{on "click" @controller.showSettings}}>
            ⚙️ Settings
          </button>
          <button class="manage-tab {{if (eq @controller.activeTab 'payouts') 'active'}}" {{on "click" @controller.showPayouts}}>
            💰 Payouts
          </button>
        {{/if}}
      </div>

    {{!-- Details Tab --}}
    {{#if (eq @controller.activeTab 'details')}}
      <div class="org-detail-grid">
        <div class="org-detail-info">
          <h2>Details</h2>
          <div class="org-info-list">
            {{#if @controller.model.email}}
              <div class="org-info-item">
                <span class="org-info-label">✉️ Email</span>
                <a href="mailto:{{@controller.model.email}}">{{@controller.model.email}}</a>
              </div>
            {{/if}}
            {{#if @controller.model.phone}}
              <div class="org-info-item">
                <span class="org-info-label">📞 Phone</span>
                <span>{{@controller.model.phone}}</span>
              </div>
            {{/if}}
            {{#if @controller.model.website}}
              <div class="org-info-item">
                <span class="org-info-label">🌐 Website</span>
                <a href={{@controller.model.website}} rel="noopener noreferrer" target="_blank">{{@controller.model.website}}</a>
              </div>
            {{/if}}
            {{#if @controller.model.address}}
              <div class="org-info-item">
                <span class="org-info-label">📍 Address</span>
                <span>{{@controller.model.address}}</span>
              </div>
            {{/if}}
            {{#if @controller.model.google_maps_url}}
              <div class="org-info-item">
                <a class="btn btn-small btn-default" href={{@controller.model.google_maps_url}} rel="noopener noreferrer" target="_blank">
                  📍 View on Google Maps
                </a>
              </div>
            {{/if}}
          </div>
        </div>
      </div>

      {{!-- Public membership section --}}
      {{#if @controller.model.membership_types.length}}
        <div class="org-memberships-public">
          <h2>🎫 Memberships</h2>
          <p class="field-help">Join {{@controller.model.name}} to become an official member.</p>
          <div class="membership-types-list">
            {{#each @controller.model.membership_types as |mtype|}}
              <div class="membership-type-card">
                <div class="membership-type-info">
                  <h3>{{mtype.name}}</h3>
                  {{#if mtype.description}}<p class="field-help">{{mtype.description}}</p>{{/if}}
                  <div class="membership-type-meta">
                    <span class="booking-class-badge">£{{mtype.price}}</span>
                    <span class="field-help">{{mtype.duration_months}} months</span>
                    {{#if mtype.discount_percentage}}
                      <span class="rule-type-badge rule-type-badge--driveline">{{mtype.discount_percentage}}% event discount</span>
                    {{/if}}
                    {{#if mtype.is_family}}
                      <span class="rule-type-badge rule-type-badge--chassis">👨‍👩‍👧 Family (up to {{mtype.max_members}})</span>
                    {{/if}}
                  </div>
                </div>
                {{#if @controller.currentUser}}
                  {{#if @controller.model.is_member}}
                    <span class="org-status org-status--active">✅ Member</span>
                  {{else}}
                    <button
                      class="btn btn-primary"
                      {{on "click" (fn @controller.joinMembership mtype.id mtype.is_family mtype.max_members)}}
                    >
                      {{if (eq @controller.joiningMembershipTypeId mtype.id) "Cancel" "Join"}}
                    </button>
                  {{/if}}
                {{else}}
                  <a class="btn btn-default" href="/login">Log in to Join</a>
                {{/if}}
                {{!-- Inline family member form --}}
                {{#if (eq @controller.joiningMembershipTypeId mtype.id)}}
                  {{#if mtype.is_family}}
                    <div class="family-inline-form">
                      <p class="field-help">Add up to {{@controller.maxFamilyMembers}} members total (including yourself).</p>
                      <div style="margin-bottom:8px;">
                        <div style="display:flex; gap:8px;">
                          <input
                            autocomplete="off"
                            placeholder="Type username to search..."
                            type="text"
                            value={{@controller.familyMemberSearch}}
                            {{on "input" @controller.updateFamilySearch}}
                          />
                          <button class="btn btn-small btn-default" {{on "click" @controller.addFamilyMemberToList}}>
                            + Add
                          </button>
                        </div>
                        {{#if @controller.familyUserSearchResults.length}}
                          <div class="family-search-results">
                            {{#each @controller.familyUserSearchResults as |user|}}
                              <div class="family-search-result" {{on "click" (fn @controller.selectFamilyUser user.username)}}>
                                <img alt={{user.username}} class="user-avatar" src={{user.avatar_template}} />
                                <span class="user-username">{{user.username}}</span>
                                {{#if user.name}}<span class="user-name">{{user.name}}</span>{{/if}}
                              </div>
                            {{/each}}
                          </div>
                        {{/if}}
                      </div>
                      {{#each @controller.familyMemberUsernames as |username|}}
                        <div class="rule-row" style="margin-bottom:4px;">
                          <span style="flex:1">👤 {{username}}</span>
                          <button class="btn btn-small btn-danger" {{on "click" (fn @controller.removeFamilyMemberFromList username)}}>✕</button>
                        </div>
                      {{/each}}
                      <div style="margin-top:12px; display:flex; gap:8px;">
                        <button class="btn btn-primary" {{on "click" @controller.confirmFamilyJoin}}>
                          Proceed to Payment
                        </button>
                        <button class="btn btn-default" {{on "click" @controller.cancelFamilyModal}}>
                          Cancel
                        </button>
                      </div>
                    </div>
                  {{/if}}
                {{/if}}
              </div>
            {{/each}}
          </div>
        </div>
      {{/if}}

      {{#if @controller.model.events.length}}
        <div class="org-detail-events">
          <h2>Upcoming Events</h2>
          <div class="org-events-list">
            {{#each @controller.model.events as |event|}}
              <div class="org-event-item">
                <DesEventLink @event={{event}}>{{event.title}}</DesEventLink>
                <div style="display:flex; gap:8px; align-items:center;">
                  <span class="event-status event-status--{{event.status}}">{{event.status}}</span>
                </div>
              </div>
            {{/each}}
          </div>
        </div>
      {{/if}}
    {{/if}}

    {{!-- Members Tab --}}
    {{#if (eq @controller.activeTab 'members')}}
      <div class="org-detail-members">
        <div class="org-section-header">
          <h2>Committee Members</h2>
          {{#if @controller.model.is_admin}}
            <button class="btn btn-small btn-primary" {{on "click" @controller.toggleAddMember}}>
              {{if @controller.showAddMember "Cancel" "+ Add Member"}}
            </button>
          {{/if}}
        </div>

        {{#if @controller.showAddMember}}
          <div class="add-member-form">
            <div class="org-form-row">
              <div class="org-form-field user-search-field">
                <label>Search User</label>
                <input
                  placeholder="Type to search users..."
                  type="text"
                  value={{@controller.newMemberUsername}}
                  {{on "input" @controller.updateUsername}}
                />
                {{#if @controller.userSearchResults.length}}
                  <div class="user-search-results">
                    {{#each @controller.userSearchResults as |user|}}
                      <div class="user-search-result" {{on "click" (fn @controller.selectUser user.username)}}>
                        <img alt={{user.username}} class="user-avatar" src={{user.avatar_template}} />
                        <span class="user-username">{{user.username}}</span>
                        {{#if user.name}}
                          <span class="user-name">{{user.name}}</span>
                        {{/if}}
                      </div>
                    {{/each}}
                  </div>
                {{/if}}
              </div>
              <div class="org-form-field">
                <label>Position</label>
                <select {{on "change" @controller.updatePosition}}>
                  <option value="">Select position...</option>
                  {{#each @controller.model.positions as |pos|}}
                    <option value={{pos.id}}>{{pos.name}}</option>
                  {{/each}}
                </select>
              </div>
            </div>
            <button class="btn btn-primary" disabled={{@controller.isSaving}} {{on "click" @controller.addMember}}>
              {{if @controller.isSaving "Adding..." "Add Member"}}
            </button>
          </div>
        {{/if}}

        {{#if @controller.model.members.length}}
          <div class="members-list">
            {{#each @controller.model.members as |member|}}
              <div class="member-item">
                <div class="member-info">
                  <strong>{{member.user.username}}</strong>
                  <span class="member-position">{{member.position.name}}</span>
                </div>
                {{#if @controller.model.is_admin}}
                  <button class="btn btn-small btn-danger" {{on "click" (fn @controller.removeMember member.id)}}>
                    Remove
                  </button>
                {{/if}}
              </div>
            {{/each}}
          </div>
        {{else}}
          <p class="field-help">No members yet.</p>
        {{/if}}
      </div>
    {{/if}}

    {{!-- Admin Memberships Section --}}
    {{#if (eq @controller.activeTab 'members')}}
      {{#if @controller.model.is_admin}}
        <div class="manage-section" style="margin-top: 24px;">
          <div class="org-section-header">
            <h2>🎫 Memberships</h2>
            <button class="btn btn-small btn-primary" {{on "click" @controller.toggleAddMembership}}>
              {{if @controller.showAddMembership "Cancel" "+ Add Membership"}}
            </button>
          </div>

          {{#if @controller.showAddMembership}}
            <div class="add-member-form">
              <div class="org-form-row">
                <div class="org-form-field">
                  <label>Username *</label>
                  <input placeholder="username" type="text" value={{@controller.newMembershipUsername}} {{on "input" (fn @controller.updateNewMembershipField "username")}} />
                </div>
                <div class="org-form-field">
                  <label>Membership Type *</label>
                  <select {{on "change" (fn @controller.updateNewMembershipField "membership_type_id")}}>
                    <option value="">Select type...</option>
                    {{#each @controller.model.membership_types as |mtype|}}
                      <option value={{mtype.id}}>{{mtype.name}}</option>
                    {{/each}}
                  </select>
                </div>
              </div>
              <div class="org-form-row">
                <div class="org-form-field">
                  <label>Expires At</label>
                  <input type="date" value={{@controller.newMembershipExpiresAt}} {{on "change" (fn @controller.updateNewMembershipField "expires_at")}} />
                </div>
                <div class="org-form-field">
                  <label>Amount Paid (£)</label>
                  <input min="0" placeholder="0" step="0.01" type="number" value={{@controller.newMembershipAmountPaid}} {{on "input" (fn @controller.updateNewMembershipField "amount_paid")}} />
                </div>
              </div>
              {{#if @controller.selectedTypeIsFamily}}
                <div class="org-form-field">
                  <label>Family Members (up to {{@controller.selectedTypeMaxFamilyMembers}})</label>
                  {{#each @controller.newMembershipFamilyUsernames as |username index|}}
                    <div class="family-username-row" style="display:flex; gap:8px; margin-bottom:4px;">
                      <input
                        placeholder="Username"
                        type="text"
                        value={{username}}
                        {{on "input" (fn @controller.updateFamilyUsername index)}}
                      />
                      <button class="btn btn-small btn-danger" {{on "click" (fn @controller.removeFamilyUsernameField index)}}>
                        Remove
                      </button>
                    </div>
                  {{/each}}
                  <button class="btn btn-small btn-default" {{on "click" @controller.addFamilyUsernameField}}>
                    + Add Family Member
                  </button>
                </div>
              {{/if}}

              <button class="btn btn-primary" {{on "click" @controller.saveAdminMembership}}>
                Add Membership
              </button>
            </div>
          {{/if}}

          {{#each @controller.adminMemberships as |m|}}
            <div class="admin-org-card">
              <div class="admin-org-info">
                <strong>{{m.username}}</strong>
                <div class="admin-org-meta">
                  <span>{{m.membership_type}}</span>
                  <span class="booking-status booking-status--{{m.status}}">{{m.status}}</span>
                  {{#if m.expires_at}}<span>Expires: {{m.expires_at}}</span>{{/if}}
                  {{#if m.is_family}}
                    <span>👨‍👩‍👧 {{m.family_members.length}}/{{m.max_members}} members</span>
                  {{/if}}
                </div>
              </div>
              <div class="admin-org-actions">
                <select class="membership-status-select" {{on "change" (fn @controller.changeMembershipStatus m)}}>
                  <option selected={{eq m.status "active"}} value="active">Active</option>
                  <option selected={{eq m.status "pending"}} value="pending">Pending</option>
                  <option selected={{eq m.status "expired"}} value="expired">Expired</option>
                  <option selected={{eq m.status "cancelled"}} value="cancelled">Cancelled</option>
                </select>
                {{#if (eq @controller.editingMembershipId m.id)}}
                  <input type="date" value={{@controller.editingMembershipExpiry}} {{on "change" @controller.updateEditingExpiry}} />
                  <button class="btn btn-primary btn-small" {{on "click" @controller.saveEditMembership}}>Save</button>
                  <button class="btn btn-default btn-small" {{on "click" @controller.cancelEditMembership}}>Cancel</button>
                {{else}}
                  <button class="btn btn-small btn-default" {{on "click" (fn @controller.editMembership m)}}>📅 Expiry</button>
                  {{#if m.is_family}}
                    <button class="btn btn-small btn-default" {{on "click" (fn @controller.toggleManageFamily m.id)}}>
                      👨‍👩‍👧 Family
                    </button>
                  {{/if}}
                  <button class="btn btn-small btn-danger" {{on "click" (fn @controller.deleteMembership m)}}>
                    🗑 Delete
                  </button>
                {{/if}}
              </div>
            </div>

            {{#if m.is_family}}
              {{#if (eq @controller.managingFamilyMembershipId m.id)}}
                <div class="family-manage-panel" style="margin-left:16px; padding:8px; border-left:3px solid var(--primary-low,#ddd); margin-bottom:8px;">
                  <h4>Family Members</h4>
                  {{#if m.family_members.length}}
                    {{#each m.family_members as |fm|}}
                      <div style="display:flex; align-items:center; gap:8px; margin-bottom:6px; flex-wrap:wrap;">
                        <strong>{{fm.username}}</strong>
                        {{#if (eq @controller.editingFamilyDobKey (concat m.id "_" fm.user_id))}}
                          <input
                            type="date"
                            value={{@controller.editingFamilyDobValue}}
                            {{on "change" @controller.updateEditingFamilyDob}}
                          />
                          <button class="btn btn-small btn-primary" {{on "click" (fn @controller.saveEditFamilyDob m.id fm.user_id)}}>Save</button>
                          <button class="btn btn-small btn-default" {{on "click" @controller.cancelEditFamilyDob}}>Cancel</button>
                        {{else}}
                          <span class="field-help">
                            DOB: {{if fm.date_of_birth fm.date_of_birth "Not set"}}
                          </span>
                          <button class="btn btn-small btn-default" {{on "click" (fn @controller.startEditFamilyDob m.id fm.user_id fm.date_of_birth)}}>
                            {{if fm.date_of_birth "Edit DOB" "Set DOB"}}
                          </button>
                        {{/if}}
                        <button class="btn btn-small btn-danger" {{on "click" (fn @controller.removeAdminFamilyMember m.id fm.user_id)}}>
                          Remove
                        </button>
                      </div>
                    {{/each}}
                  {{else}}
                    <p class="field-help">No family members added yet.</p>
                  {{/if}}

                  <div style="display:flex; gap:8px; margin-top:8px; align-items:flex-end;">
                    <div>
                      <label class="field-help">Username</label>
                      <input
                        placeholder="Username"
                        type="text"
                        value={{@controller.newFamilyMemberUsername}}
                        {{on "input" @controller.updateNewFamilyMemberUsername}}
                      />
                    </div>
                    <div>
                      <label class="field-help">Date of Birth</label>
                      <input
                        type="date"
                        value={{@controller.newFamilyMemberDob}}
                        {{on "change" @controller.updateNewFamilyMemberDob}}
                      />
                    </div>
                    <button class="btn btn-small btn-primary" {{on "click" (fn @controller.addAdminFamilyMember m.id)}}>
                      Add
                    </button>
                  </div>
                </div>
              {{/if}}
            {{/if}}
          {{/each}}
        </div>
      {{/if}}
    {{/if}}

    {{!-- Events Tab --}}
    {{#if (eq @controller.activeTab 'events')}}
      <div class="org-detail-events">
        <div class="org-section-header">
          <h2>Events</h2>
          <LinkTo class="btn btn-small btn-primary" @route="event-new">+ New Event</LinkTo>
        </div>
        {{#if @controller.model.events.length}}
          <div class="org-events-list">
            {{#each @controller.model.events as |event|}}
              <div class="org-event-item">
                <DesEventLink @event={{event}}>{{event.title}}</DesEventLink>
                <div style="display:flex; gap:8px; align-items:center;">
                  <span class="event-status event-status--{{event.status}}">{{event.status}}</span>
                  <LinkTo class="btn btn-small btn-default" @model={{event.id}} @route="event-manage">
                    ⚙️ Manage
                  </LinkTo>
                </div>
              </div>
            {{/each}}
          </div>
        {{else}}
          <p class="field-help">No events yet.</p>
        {{/if}}
      </div>
    {{/if}}

    {{!-- Class Rules Tab --}}
    {{#if (eq @controller.activeTab 'rules')}}
      <div class="manage-section">
        <h2>Organisation Class Types</h2>
        <p class="field-help">Create custom class types for your organisation's events. Leave fields blank to allow any value.</p>

        <button class="btn btn-primary btn-small" {{on "click" @controller.toggleAddOrgClassTypeForm}}>
          {{if @controller.showAddOrgClassTypeForm "✕ Cancel" "+ Add Class Type"}}
        </button>

        {{#if @controller.showAddOrgClassTypeForm}}
          <DesClassTypeForm
            @manufacturers={{@controller.model.manufacturers}}
            @models={{@controller.model.approved_models}}
            @onCancel={{@controller.toggleAddOrgClassTypeForm}}
            @onSave={{@controller.createOrgClassType}}
            @saveLabel="+ Create Class"
          />
        {{/if}}

        <h3 style="margin-top: 24px;">Your Organisation's Class Types</h3>
        {{#if @controller.model.org_class_types.length}}
          {{#each @controller.model.org_class_types as |ct|}}
            <div class="admin-org-card">
              <div class="admin-org-info">
                <strong>{{ct.name}}</strong>
                <div class="admin-org-meta">
                  {{#if ct.track_environment}}<span>{{if (eq ct.track_environment "onroad") "🛣️ On-Road" "🌿 Off-Road"}}</span>{{/if}}
                  {{#if ct.scale}}<span>📏 {{ct.scale}}</span>{{/if}}
                  {{#if ct.chassis_types.length}}<span>🚗 {{ct.chassis_types}}</span>{{/if}}
                  {{#if ct.drivelines.length}}<span>⚙️ {{ct.drivelines}}</span>{{/if}}
                  {{#if ct.min_year}}<span>📅 From {{ct.min_year}}</span>{{/if}}
                  {{#if ct.max_year}}<span>📅 Until {{ct.max_year}}</span>{{/if}}
                  {{#if ct.manufacturer}}<span>🏭 {{ct.manufacturer}}</span>{{/if}}
                  {{#if ct.min_age}}<span>👤 Age {{ct.min_age}}+</span>{{/if}}
                  {{#if ct.max_age}}<span>👤 Age ≤{{ct.max_age}}</span>{{/if}}
                </div>
              </div>
              <div class="admin-org-actions">
                <button class="btn btn-default btn-small" {{on "click" (fn @controller.startEditOrgClassType ct)}}>✏️ Edit</button>
                <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteClassType ct.id)}}>🗑 Delete</button>
              </div>
            </div>
            {{#if (eq @controller.editingOrgClassTypeId ct.id)}}
              <DesClassTypeForm
                @classType={{ct}}
                @manufacturers={{@controller.model.manufacturers}}
                @models={{@controller.model.approved_models}}
                @onCancel={{@controller.cancelEditOrgClassType}}
                @onSave={{@controller.saveEditOrgClassType}}
                @saveLabel="💾 Save Changes"
              />
            {{/if}}
          {{/each}}
        {{else}}
          <p class="field-help">No custom class types yet.</p>
        {{/if}}

        <h3 style="margin-top: 32px;">Global Class Types</h3>
        <p class="field-help">Available to all organisations. Cannot be edited here.</p>
        {{#each @controller.model.global_class_types as |ct|}}
          <div class="admin-org-card">
            <div class="admin-org-info">
              <strong>{{ct.name}}</strong>
              <div class="admin-org-meta">
                {{#if ct.track_environment}}<span>{{if (eq ct.track_environment "onroad") "🛣️ On-Road" "🌿 Off-Road"}}</span>{{/if}}
                {{#if ct.scale}}<span>📏 {{ct.scale}}</span>{{/if}}
                {{#if ct.chassis_types.length}}<span>🚗 {{ct.chassis_types}}</span>{{/if}}
                {{#if ct.drivelines.length}}<span>⚙️ {{ct.drivelines}}</span>{{/if}}
                {{#if ct.min_year}}<span>📅 From {{ct.min_year}}</span>{{/if}}
                {{#if ct.max_year}}<span>📅 Until {{ct.max_year}}</span>{{/if}}
                {{#if ct.manufacturer}}<span>🏭 {{ct.manufacturer}}</span>{{/if}}
                {{#if ct.min_age}}<span>👤 Age {{ct.min_age}}+</span>{{/if}}
                {{#if ct.max_age}}<span>👤 Age ≤{{ct.max_age}}</span>{{/if}}
              </div>
            </div>
          </div>
        {{/each}}
      </div>
    {{/if}}

    {{!-- Memberships Tab --}}
    {{#if (eq @controller.activeTab 'memberships')}}
      <div class="manage-section">
        <h2>Membership Types</h2>
        <p class="field-help">Set up membership types that users can purchase to join your organisation.</p>

        <div class="admin-rule-form">
          <h3>Add Membership Type</h3>
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Name</label>
              <input id="mtype-name" placeholder="e.g. Annual Member" type="text" />
            </div>
            <div class="org-form-field">
              <label>Price (£)</label>
              <input id="mtype-price" min="0" placeholder="30.00" step="0.01" type="number" />
            </div>
            <div class="org-form-field">
              <label>Duration (months)</label>
              <input id="mtype-duration" min="1" placeholder="12" type="number" />
            </div>
          </div>
          <div class="org-form-row">
            <div class="org-form-field">
              <label>Description <span class="field-help">(optional)</span></label>
              <input id="mtype-desc" placeholder="Brief description" type="text" />
            </div>
            <div class="org-form-field">
              <label>Event Discount % <span class="field-help">(optional)</span></label>
              <input id="mtype-discount" max="100" min="0" placeholder="0" type="number" />
            </div>
            <div class="org-form-field">
              <label>Max Members <span class="field-help">(1 = individual, 2+ = family)</span></label>
              <input id="mtype-max-members" max="10" min="1" placeholder="1" type="number" value="1" />
            </div>
            <div class="org-form-field" style="justify-content: flex-end;">
              <button class="btn btn-primary" {{on "click" @controller.createMembershipType}}>
                + Add Type
              </button>
            </div>
          </div>
        </div>

        {{#if @controller.model.membership_types.length}}
          {{#each @controller.model.membership_types as |mtype|}}
            <div class="rules-class-group">
              <div class="org-section-header">
                <div>
                  <h4>{{mtype.name}}
                    <span class="booking-class-badge">£{{mtype.price}}</span>
                    <span class="field-help">{{mtype.duration_months}} months</span>
                    {{#if mtype.discount_percentage}}
                      <span class="rule-type-badge rule-type-badge--driveline">{{mtype.discount_percentage}}% discount</span>
                    {{/if}}
                    {{#if mtype.is_family}}
                      <span class="rule-type-badge rule-type-badge--chassis">👨‍👩‍👧 Family (up to {{mtype.max_members}})</span>
                    {{/if}}
                  </h4>
                  {{#if mtype.description}}<p class="field-help">{{mtype.description}}</p>{{/if}}
                </div>
                <button class="btn btn-small btn-danger" {{on "click" (fn @controller.deleteMembershipType mtype.id)}}>
                  🗑 Remove
                </button>
              </div>
            </div>
          {{/each}}
        {{else}}
          <p class="field-help">No membership types yet. Add one above!</p>
        {{/if}}
      </div>
    {{/if}}


    {{!-- Settings Tab --}}
    {{#if (eq @controller.activeTab "settings")}}
      <div class="manage-section">
        <h2>Organisation Settings</h2>
        <div class="org-form-row">
          <div class="org-form-field">
            <label>Organisation Name *</label>
            <input type="text" value={{@controller.settingsForm.name}} {{on "input" (fn @controller.updateSettingsField "name")}} />
          </div>
          <div class="org-form-field">
            <label>Email</label>
            <input type="email" value={{@controller.settingsForm.email}} {{on "input" (fn @controller.updateSettingsField "email")}} />
          </div>
        </div>
        <div class="org-form-row">
          <div class="org-form-field">
            <label>Phone</label>
            <input type="text" value={{@controller.settingsForm.phone}} {{on "input" (fn @controller.updateSettingsField "phone")}} />
          </div>
          <div class="org-form-field">
            <label>Website</label>
            <input type="url" value={{@controller.settingsForm.website}} {{on "input" (fn @controller.updateSettingsField "website")}} />
          </div>
        </div>
        <div class="org-form-field">
          <label>Logo URL</label>
          <input placeholder="https://example.com/logo.png" type="url" value={{@controller.settingsForm.logo_url}} {{on "input" (fn @controller.updateSettingsField "logo_url")}} />
          {{#if @controller.settingsForm.logo_url}}
            <img alt="Preview" class="org-logo org-logo--small" src={{@controller.settingsForm.logo_url}} style="margin-top:8px;" />
          {{/if}}
        </div>
        <div class="org-form-field">
          <label>Address</label>
          <input type="text" value={{@controller.settingsForm.address}} {{on "input" (fn @controller.updateSettingsField "address")}} />
        </div>
        <div class="org-form-field">
          <label>Google Maps URL</label>
          <input type="url" value={{@controller.settingsForm.google_maps_url}} {{on "input" (fn @controller.updateSettingsField "google_maps_url")}} />
        </div>
        <div class="org-form-field">
          <label>PayPal Email</label>
          <input placeholder="payments@yourclub.com" type="email" value={{@controller.settingsForm.paypal_email}} {{on "input" (fn @controller.updateSettingsField "paypal_email")}} />
        </div>
        <div class="org-form-field">
          <label>Surcharge % <span class="field-help">(platform fee deducted from payouts)</span></label>
          <input max="100" min="0" step="0.1" type="number" value={{@controller.settingsForm.surcharge_percentage}} {{on "input" (fn @controller.updateSettingsField "surcharge_percentage")}} />
        </div>
        <div class="org-form-field">
          <label>RC Results Venue ID</label>
          <input placeholder="e.g. 1075" type="number" value={{@controller.settingsForm.rc_results_venue_id}} {{on "input" (fn @controller.updateSettingsField "rc_results_venue_id")}} />
        </div>
        <div class="org-form-field">
          <label>Description</label>
          <textarea rows="4" {{on "input" (fn @controller.updateSettingsField "description")}}>{{@controller.settingsForm.description}}</textarea>
        </div>
        <button class="btn btn-primary" {{on "click" @controller.saveSettings}}>
          💾 Save Settings
        </button>
      </div>
    {{/if}}

    {{!-- Payouts Tab --}}
    {{#if (eq @controller.activeTab "payouts")}}
      <div class="org-payouts-tab">
        {{#if @controller.payoutsLoading}}
          <p>Loading payouts...</p>
        {{else}}
          <div class="payout-summary-cards">
            <div class="payout-summary-card">
              <div class="payout-summary-label">Total Paid Out</div>
              <div class="payout-summary-value">£{{@controller.payoutsSummary.total_paid}}</div>
            </div>
            <div class="payout-summary-card">
              <div class="payout-summary-label">Pending</div>
              <div class="payout-summary-value">£{{@controller.payoutsSummary.total_pending}}</div>
            </div>
          </div>

          {{#if @controller.orgPayouts.length}}
            <table class="payout-history-table">
              <thead>
                <tr>
                  <th>Event</th>
                  <th>Date</th>
                  <th>Gross</th>
                  <th>Net</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {{#each @controller.orgPayouts as |payout|}}
                  <tr class="payout-row payout-status--{{payout.status}}">
                    <td>{{payout.event_title}}</td>
                    <td>{{payout.event_date}}</td>
                    <td>£{{payout.gross_amount}}</td>
                    <td>£{{payout.net_amount}}</td>
                    <td><span class="payout-status-badge payout-status--{{payout.status}}">{{payout.status}}</span></td>
                    <td>
                      {{#if (eq payout.status "approved")}}
                        <button class="btn btn-primary btn-small" disabled={{@controller.claimingPayoutId}} {{on "click" (fn @controller.claimPayout payout)}}>
                          {{if (eq @controller.claimingPayoutId payout.event_id) "Processing..." "💰 Claim"}}
                        </button>
                      {{else if (eq payout.status "failed")}}
                        <button class="btn btn-danger btn-small" disabled={{@controller.claimingPayoutId}} {{on "click" (fn @controller.retryPayout payout)}}>
                          {{if (eq @controller.claimingPayoutId payout.event_id) "Processing..." "🔄 Retry"}}
                        </button>
                      {{else}}
                        <a class="btn btn-default btn-small" href="/events/{{payout.event_id}}/manage">View</a>
                      {{/if}}
                    </td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          {{else}}
            <p class="field-help">No payouts yet.</p>
          {{/if}}
        {{/if}}
      </div>
    {{/if}}

    {{!-- Venues Tab --}}
    {{#if (eq @controller.activeTab "venues")}}
      <div class="des-admin-section">
        <h2>📍 Venues</h2>
        {{#if @controller.model.venues.length}}
          {{#each @controller.model.venues as |venue|}}
            <div class="org-venue-item" style="display:flex;align-items:center;gap:8px;padding:8px 12px;background:var(--primary-very-low);border-radius:6px;margin-bottom:6px;flex-wrap:wrap;">
              <LinkTo @model={{venue.id}} @route="venue">
                <strong>{{venue.name}}</strong>
              </LinkTo>
              {{#if venue.address}}<span class="field-help">📍 {{venue.address}}</span>{{/if}}
              {{#if venue.is_stub}}<span class="venue-badge" style="background:var(--highlight-low);color:var(--highlight-high);font-size:0.8em;padding:2px 6px;border-radius:3px;">Stub</span>{{/if}}
              {{#each venue.tracks as |track|}}
                {{#if track.surface}}<span class="venue-badge venue-badge--surface">{{track.surface}}</span>{{/if}}
                {{#if track.environment}}<span class="venue-badge venue-badge--environment">{{track.environment}}</span>{{/if}}
              {{/each}}
            </div>
          {{/each}}
        {{else}}
          <p class="field-help">No venues linked to this organisation.</p>
        {{/if}}
      </div>
    {{/if}}
  </div>
</template>
