import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import { eq } from "discourse/truth-helpers";

export default <template>
  <div class="racing-profile-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="my-organisations">🏢 My Organisations</LinkTo>
      <LinkTo class="btn btn-default" @route="racing-profile">🏎️ My Racing Profile</LinkTo>
      <LinkTo class="btn btn-default" @route="my-garage">🚗 My Garage</LinkTo>
      <LinkTo class="btn btn-default" @route="my-bookings">🎟️ My Bookings</LinkTo>
      <LinkTo class="btn btn-default" @route="my-memberships">🎫 My Memberships</LinkTo>
    </div>

    <h1>🏎️ My Racing Profile</h1>

    <div class="profile-section">
      <h2>Personal Details</h2>

      <div class="org-form-field">
        <label>Date of Birth</label>
        <p class="field-help">Used to calculate eligibility for age-based discounts (e.g. junior pricing)</p>
        <input
          type="date"
          value={{@controller.model.profile.user.date_of_birth}}
          {{on "change" @controller.setDateOfBirth}}
        />
      </div>

      <div class="org-form-field" style="margin-top: 16px;">
        <label>BRCA Membership Number</label>
        <p class="field-help">Required after your first 3 bookings</p>
        <input
          placeholder="e.g. 221708"
          type="text"
          value={{@controller.model.profile.user.brca_membership_number}}
          {{on "input" @controller.setBrcaNumber}}
        />
      </div>

      <div class="org-form-field" style="margin-top: 16px;">
        <label>Home Postcode</label>
        <p class="field-help">Used to calculate distance to events</p>
        <input
          placeholder="e.g. S6 1LU"
          type="text"
          value={{@controller.postcode}}
          {{on "input" @controller.updatePostcode}}
        />
      </div>

      <div class="org-form-row" style="margin-top: 16px;">
        <div class="org-form-field">
          <label>F Grade (Formula)</label>
          <select {{on "change" @controller.setFGrade}}>
            <option selected={{eq @controller.model.profile.user.f_grade "0"}} value="0">0</option>
            <option selected={{eq @controller.model.profile.user.f_grade "1"}} value="1">1</option>
            <option selected={{eq @controller.model.profile.user.f_grade "2"}} value="2">2</option>
            <option selected={{eq @controller.model.profile.user.f_grade "3"}} value="3">3</option>
            <option selected={{eq @controller.model.profile.user.f_grade "4"}} value="4">4</option>
            <option selected={{eq @controller.model.profile.user.f_grade "5"}} value="5">5</option>
          </select>
        </div>
        <div class="org-form-field">
          <label>T Grade (Truck Grade)</label>
          <select {{on "change" @controller.setTGrade}}>
            <option selected={{eq @controller.model.profile.user.t_grade "0"}} value="0">0</option>
            <option selected={{eq @controller.model.profile.user.t_grade "1"}} value="1">1</option>
            <option selected={{eq @controller.model.profile.user.t_grade "2"}} value="2">2</option>
            <option selected={{eq @controller.model.profile.user.t_grade "3"}} value="3">3</option>
            <option selected={{eq @controller.model.profile.user.t_grade "4"}} value="4">4</option>
            <option selected={{eq @controller.model.profile.user.t_grade "5"}} value="5">5</option>
          </select>
        </div>
      </div>


      <button class="btn btn-primary" style="margin-top: 16px;" {{on "click" @controller.saveProfile}}>
        Save Details
      </button>
    </div>


    {{!-- Transponder Registry --}}
    <div class="profile-section" style="margin-top: 24px;">
      <h2>📡 My Transponders</h2>
      <p class="field-help">Your transponder registry. Use shortcodes when entering transponders on your cars.</p>

      {{#if @controller.transponders.length}}
        <div class="transponder-list">
          {{#each @controller.transponders as |t|}}
            <div class="admin-org-card">
              {{#if (eq @controller.editingTransponderId t.id)}}
                <div class="org-form-row">
                  <div class="org-form-field">
                    <label>Long Code</label>
                    <input type="text" value={{@controller.editTransponderCode}} {{on "input" @controller.updateEditTransponderCode}} />
                  </div>
                  <div class="org-form-field">
                    <label>Notes</label>
                    <input placeholder="e.g. blue one" type="text" value={{@controller.editTransponderNotes}} {{on "input" @controller.updateEditTransponderNotes}} />
                  </div>
                </div>
                <div class="admin-org-actions">
                  <button class="btn btn-primary btn-small" {{on "click" (fn @controller.saveTransponder t)}}>💾 Save</button>
                  <button class="btn btn-default btn-small" {{on "click" @controller.cancelEditTransponder}}>✕ Cancel</button>
                </div>
              {{else}}
                <div class="admin-org-info">
                  <strong>#{{t.shortcode}} — {{t.long_code}}</strong>
                  {{#if t.notes}}<span class="field-help"> ({{t.notes}})</span>{{/if}}
                </div>
                <div class="admin-org-actions">
                  <button class="btn btn-default btn-small" {{on "click" (fn @controller.startEditTransponder t)}}>✏️ Edit</button>
                  <button class="btn btn-danger btn-small" {{on "click" (fn @controller.deleteTransponder t)}}>🗑 Delete</button>
                </div>
              {{/if}}
            </div>
          {{/each}}
        </div>
      {{else}}
        <p class="field-help">No transponders registered yet.</p>
      {{/if}}

      <div class="transponder-add-form" style="margin-top: 16px;">
        <h3>Add Transponder</h3>
        <div class="org-form-row">
          <div class="org-form-field">
            <label>Long Code *</label>
            <input placeholder="e.g. 7456985" type="text" value={{@controller.newTransponderCode}} {{on "input" @controller.updateNewTransponderCode}} {{on "blur" @controller.validateTransponderCode}} />
            {{#if @controller.transponderError}}
              <p class="field-help" style="color:var(--danger);margin:2px 0 0;">{{@controller.transponderError}}</p>
            {{/if}}
          </div>
          <div class="org-form-field">
            <label>Notes</label>
            <input placeholder="e.g. blue one" type="text" value={{@controller.newTransponderNotes}} {{on "input" @controller.updateNewTransponderNotes}} />
          </div>
          <div class="org-form-field" style="justify-content: flex-end;">
            <button class="btn btn-primary" {{on "click" @controller.addTransponder}}>➕ Add Transponder</button>
          </div>
        </div>
      </div>
    </div>

    {{!-- My Parent/Guardian Section --}}
    <div class="profile-section" style="margin-top: 24px;">
      <h2>🛡️ My Parent/Guardian</h2>
      <p class="field-help">Set your parent or guardian so they can book events on your behalf.</p>

      {{#if @controller.guardianError}}
        <div class="alert alert-error family-error">{{@controller.guardianError}}</div>
      {{/if}}

      {{#if @controller.myGuardian}}
        <div class="family-member-row">
          <div class="family-member-info">
            {{#if @controller.myGuardian.avatar_url}}
              <img alt="" class="user-avatar" src={{@controller.myGuardian.avatar_url}} />
            {{/if}}
            <span class="user-username">{{@controller.myGuardian.username}}</span>
            {{#if @controller.myGuardian.name}}<span class="user-name">— {{@controller.myGuardian.name}}</span>{{/if}}
          </div>
          <div class="family-member-actions">
            <button class="btn btn-small btn-danger" {{on "click" @controller.removeGuardian}}>Remove</button>
          </div>
        </div>
      {{else}}
        <div class="family-search-box">
          <label>Search for your parent/guardian:</label>
          <input
            class="family-search-input"
            placeholder="Type their username..."
            type="text"
            {{on "input" @controller.searchGuardian}}
          />
        </div>
        {{#if @controller.guardianSearchResults.length}}
          <div class="family-search-results">
            {{#each @controller.guardianSearchResults as |user|}}
              <div class="family-search-result" role="button" {{on "click" (fn @controller.selectGuardian user)}}>
                {{#if user.avatar_template}}
                  <img alt="" class="user-avatar" src={{user.avatar_template}} />
                {{/if}}
                <span class="user-username">{{user.username}}</span>
                {{#if user.name}}<span class="user-name">— {{user.name}}</span>{{/if}}
              </div>
            {{/each}}
          </div>
        {{/if}}
      {{/if}}
    </div>

    {{!-- Family Members Section --}}
    <div class="profile-section" style="margin-top: 24px;">
      <h2>👨‍👩‍👧 My Dependants</h2>
      <p class="field-help">Users you are guardian of. You can book events on their behalf.</p>

      {{#if @controller.familyError}}
        <div class="alert alert-error family-error">{{@controller.familyError}}</div>
      {{/if}}

      {{#if @controller.createdFamilyAccounts.length}}
        <div class="created-accounts-summary">
          <h3>📋 New Account Login Details</h3>
          <p class="field-help">Please save these — passwords cannot be retrieved later.</p>
          <table class="family-accounts-table">
            <thead><tr><th>Username</th><th>Password</th></tr></thead>
            <tbody>
              {{#each @controller.createdFamilyAccounts as |account|}}
                <tr>
                  <td><strong>{{account.username}}</strong></td>
                  <td><code>{{account.password}}</code></td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{/if}}

      {{#if @controller.familyMembers.length}}
        <div class="family-current-members">
          {{#each @controller.familyMembers as |member|}}
            <div class="family-member-row">
              {{#if (eq @controller.editingFamilyId member.user_id)}}
                <div class="family-member-edit" style="width:100%;">
                  <strong>{{member.username}}</strong>
                  <div class="org-form-row" style="margin-top:8px;">
                    <div class="org-form-field">
                      <label>Date of Birth</label>
                      <input type="date" value={{@controller.editFamDob}} {{on "input" @controller.setEditFamDob}} />
                    </div>
                    <div class="org-form-field">
                      <label>BRCA Number</label>
                      <input placeholder="Optional" type="text" value={{@controller.editFamBrca}} {{on "input" @controller.setEditFamBrca}} />
                    </div>
                  </div>
                  <div style="display:flex;gap:6px;margin-top:8px;">
                    <button class="btn btn-small btn-primary" {{on "click" (fn @controller.saveEditFamily member)}}>Save</button>
                    <button class="btn btn-small btn-default" {{on "click" @controller.cancelEditFamily}}>Cancel</button>
                  </div>
                </div>
              {{else}}
                <div class="family-member-info">
                  {{#if member.avatar_url}}
                    <img alt="" class="user-avatar" src={{member.avatar_url}} />
                  {{/if}}
                  <span class="user-username">{{member.username}}</span>
                  {{#if member.name}}<span class="user-name">— {{member.name}}</span>{{/if}}
                  {{#if member.date_of_birth}}<span class="member-detail">DOB: {{member.date_of_birth}}</span>{{/if}}
                  {{#if member.brca_membership_number}}<span class="member-detail">BRCA: {{member.brca_membership_number}}</span>{{/if}}
                </div>
                <div class="family-member-actions">
                  <button class="btn btn-small btn-default" {{on "click" (fn @controller.startEditFamily member)}}>Edit</button>
                  <button class="btn btn-small btn-danger" {{on "click" (fn @controller.removeFamilyMember member)}}>Remove</button>
                </div>
              {{/if}}
            </div>
          {{/each}}
        </div>
      {{/if}}

      <div class="family-add-section" style="margin-top:16px;">
        <h3>Add Dependant</h3>
        <p class="field-help">If your dependant does not already have an account, you can create one for them here.</p>

        <div class="family-create-form">
          <div class="family-form-field">
            <label>Username <span class="required">*</span></label>
            <input placeholder="username" type="text" value={{@controller.newFamUsername}} {{on "input" @controller.setNewFamUsername}} />
          </div>
          <div class="family-form-field">
            <label>Full Name <span class="required">*</span></label>
            <input placeholder="Full Name" type="text" value={{@controller.newFamName}} {{on "input" @controller.setNewFamName}} />
          </div>
          <div class="family-form-field">
            <label>Date of Birth <span class="required">*</span></label>
            <input type="date" value={{@controller.newFamDob}} {{on "input" @controller.setNewFamDob}} />
          </div>
          <div class="family-form-field">
            <label>BRCA Number</label>
            <input placeholder="Optional" type="text" value={{@controller.newFamBrca}} {{on "input" @controller.setNewFamBrca}} />
          </div>
          <div class="family-form-field">
            <label>Email</label>
            <input placeholder="Optional — auto-generated if blank" type="email" value={{@controller.newFamEmail}} {{on "input" @controller.setNewFamEmail}} />
          </div>
          <button class="btn btn-primary" disabled={{@controller.familyCreating}} {{on "click" @controller.createFamilyUser}}>
            {{if @controller.familyCreating "Creating..." "Create & Add Dependant"}}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
