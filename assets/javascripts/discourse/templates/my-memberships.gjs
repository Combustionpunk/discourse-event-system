import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";

export default <template>
  <div class="my-memberships-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="my-organisations">🏢 My Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="racing-profile">🏎️ My Racing Profile</LinkTo>
      <LinkTo class="btn btn-default" @route="my-garage">🚗 My Garage</LinkTo>
      <LinkTo class="btn btn-default" @route="my-bookings">🎟️ My Bookings</LinkTo>
      <LinkTo class="btn btn-default" @route="my-memberships">🎫 My Memberships</LinkTo>
    </div>

    <h1>🎫 My Memberships</h1>

    {{#if @controller.model.memberships.length}}
      <div class="memberships-list">
        {{#each @controller.model.memberships as |membership|}}
          <div class="membership-card membership-card--{{membership.status}}">
            <div class="membership-card-header">
              <div>
                <h3>{{membership.organisation.name}}</h3>
                <span class="membership-type-name">{{membership.membership_type.name}}</span>
              </div>
              <span class="membership-status-badge membership-status-badge--{{membership.status}}">
                {{membership.status}}
              </span>
            </div>

            <div class="membership-card-details">
              <div class="membership-detail-item">
                <span class="membership-detail-label">💰 Paid</span>
                <span>£{{membership.amount_paid}}</span>
              </div>
              <div class="membership-detail-item">
                <span class="membership-detail-label">📅 Starts</span>
                <span>{{@controller.formatDate membership.starts_at}}</span>
              </div>
              <div class="membership-detail-item">
                <span class="membership-detail-label">⏰ Expires</span>
                <span class={{if (@controller.isExpiringSoon membership.expires_at) 'expiring-soon'}}>
                  {{@controller.formatDate membership.expires_at}}
                </span>
              </div>
              {{#if membership.family_members_count}}
                <div class="membership-detail-item">
                  <span class="membership-detail-label">👨‍👩‍👧 Family</span>
                  <span>{{membership.family_members_count}} additional members</span>
                </div>
              {{/if}}
            </div>

            <div class="membership-card-actions">
              <LinkTo class="btn btn-small btn-default" @model={{membership.organisation.id}} @route="organisation">
                View Organisation
              </LinkTo>
              {{#if membership.is_family}}
                <button class="btn btn-small btn-default" type="button" {{on "click" (fn @controller.toggleFamilyPanel membership.id)}}>
                  👨‍👩‍👧 Manage Family
                </button>
              {{/if}}
              <button class="btn btn-small btn-primary" type="button" {{on "click" (fn @controller.renewMembership membership)}}>
                🔄 Renew
              </button>
            </div>

            {{#if membership.is_family}}
              {{#if (eq @controller.expandedFamilyId membership.id)}}
                <div class="family-manage-panel">
                  <h4>👨‍👩‍👧 Family Members</h4>

                  {{#if @controller.familyError}}
                    <div class="alert alert-error family-error">{{@controller.familyError}}</div>
                  {{/if}}

                  {{#if @controller.familyCreatedAccounts.length}}
                    <div class="created-accounts-summary">
                      <h5>📋 New Account Login Details</h5>
                      <p class="field-help">Save these — passwords cannot be retrieved later.</p>
                      <table class="family-accounts-table">
                        <thead><tr><th>Username</th><th>Password</th></tr></thead>
                        <tbody>
                          {{#each @controller.familyCreatedAccounts as |account|}}
                            <tr>
                              <td><strong>{{account.username}}</strong></td>
                              <td><code>{{account.password}}</code></td>
                            </tr>
                          {{/each}}
                        </tbody>
                      </table>
                    </div>
                  {{/if}}

                  {{#if membership.family_members.length}}
                    <div class="family-members-list">
                      {{#each membership.family_members as |member|}}
                        <div class="family-member-row">
                          {{#if (eq @controller.editingMemberId member.user_id)}}
                            <div class="family-member-edit">
                              <span class="user-username">{{member.username}}</span>
                              <div class="family-form-field">
                                <label>Date of Birth</label>
                                <input type="date" value={{@controller.editDob}} {{on "input" @controller.setEditDob}} />
                              </div>
                              <div class="family-form-field">
                                <label>BRCA Number</label>
                                <input placeholder="Optional" type="text" value={{@controller.editBrca}} {{on "input" @controller.setEditBrca}} />
                              </div>
                              <div class="family-edit-actions">
                                <button class="btn btn-small btn-primary" type="button" {{on "click" (fn @controller.saveEditMember membership member)}}>Save</button>
                                <button class="btn btn-small btn-default" type="button" {{on "click" @controller.cancelEditMember}}>Cancel</button>
                              </div>
                            </div>
                          {{else}}
                            <div class="family-member-info">
                              {{#if member.avatar_url}}
                                <img alt="" class="user-avatar" src={{member.avatar_url}} />
                              {{/if}}
                              <span class="user-username">{{member.username}}</span>
                              {{#if member.date_of_birth}}<span class="member-detail">DOB: {{member.date_of_birth}}</span>{{/if}}
                              {{#if member.brca_membership_number}}<span class="member-detail">BRCA: {{member.brca_membership_number}}</span>{{/if}}
                            </div>
                            <div class="family-member-actions">
                              <button class="btn btn-small btn-default" type="button" {{on "click" (fn @controller.startEditMember member)}}>Edit</button>
                              <button class="btn btn-small btn-danger" type="button" {{on "click" (fn @controller.removeFamilyMember membership member)}}>Remove</button>
                            </div>
                          {{/if}}
                        </div>
                      {{/each}}
                    </div>
                  {{else}}
                    <p class="field-help">No family members added yet.</p>
                  {{/if}}

                  {{#if (@controller.canAddMoreFamily membership)}}
                    <div class="family-add-section">
                      <h5>Add Family Member</h5>
                      <div class="family-search-box">
                        <label>Search existing user:</label>
                        <input
                          class="family-search-input"
                          placeholder="Type username or name..."
                          type="text"
                          value={{@controller.familySearchTerm}}
                          {{on "input" @controller.onFamilySearch}}
                        />
                      </div>

                      {{#if @controller.familySearchResults.length}}
                        <div class="family-search-results">
                          {{#each @controller.familySearchResults as |user|}}
                            <div class="family-search-result" role="button" {{on "click" (fn @controller.selectFamilyUser membership user)}}>
                              {{#if user.avatar_template}}
                                <img alt="" class="user-avatar" src={{user.avatar_template}} />
                              {{/if}}
                              <span class="user-username">{{user.username}}</span>
                              {{#if user.name}}<span class="user-name">— {{user.name}}</span>{{/if}}
                            </div>
                          {{/each}}
                        </div>
                      {{/if}}

                      {{#if @controller.familyAddingMember}}
                        <div class="family-loading">Adding member...</div>
                      {{/if}}

                      <div class="family-or-divider"><span>— OR —</span></div>

                      <button class="btn btn-default btn-small" type="button" {{on "click" @controller.toggleFamilyCreateForm}}>
                        {{#if @controller.showFamilyCreateForm}}Hide Create Form{{else}}➕ Create New Account{{/if}}
                      </button>

                      {{#if @controller.showFamilyCreateForm}}
                        <div class="family-create-form">
                          <div class="family-form-field">
                            <label>Username <span class="required">*</span></label>
                            <input placeholder="username" type="text" value={{@controller.familyNewUsername}} {{on "input" @controller.setFamilyNewUsername}} />
                          </div>
                          <div class="family-form-field">
                            <label>Full Name <span class="required">*</span></label>
                            <input placeholder="Full Name" type="text" value={{@controller.familyNewName}} {{on "input" @controller.setFamilyNewName}} />
                          </div>
                          <div class="family-form-field">
                            <label>Date of Birth <span class="required">*</span></label>
                            <input type="date" value={{@controller.familyNewDob}} {{on "input" @controller.setFamilyNewDob}} />
                          </div>
                          <div class="family-form-field">
                            <label>BRCA Number</label>
                            <input placeholder="Optional" type="text" value={{@controller.familyNewBrca}} {{on "input" @controller.setFamilyNewBrca}} />
                          </div>
                          <div class="family-form-field">
                            <label>Email</label>
                            <input placeholder="Optional — auto-generated if blank" type="email" value={{@controller.familyNewEmail}} {{on "input" @controller.setFamilyNewEmail}} />
                          </div>
                          <button class="btn btn-primary" disabled={{@controller.familyCreatingUser}} type="button"
                            {{on "click" (fn @controller.createFamilyUser membership)}}>
                            {{#if @controller.familyCreatingUser}}Creating...{{else}}Create & Add Member{{/if}}
                          </button>
                        </div>
                      {{/if}}
                    </div>
                  {{/if}}
                </div>
              {{/if}}
            {{/if}}
          </div>
        {{/each}}
      </div>
    {{else}}
      <div class="empty-state">
        <p>You don't have any memberships yet.</p>
        <LinkTo class="btn btn-primary" @route="organisations">Browse Organisations</LinkTo>
      </div>
    {{/if}}
  </div>
</template>
