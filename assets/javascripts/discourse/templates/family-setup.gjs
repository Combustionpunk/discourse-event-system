import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";

export default <template>
  <div class="family-setup-container">
    <div class="events-nav">
      <LinkTo class="btn btn-default" @route="my-memberships">🎫 My Memberships</LinkTo>
    </div>

    {{#if @controller.model.error}}
      <div class="booking-error">
        <div class="booking-success-icon">❌</div>
        <h1>Error</h1>
        <p>{{@controller.model.error}}</p>
      </div>
    {{else if @controller.completed}}
      <div class="booking-success">
        <div class="booking-success-icon">🎉</div>
        <h1>Family Membership Set Up!</h1>
        <p>Your family membership for <strong>{{@controller.model.organisation_name}}</strong> is ready.</p>

        {{#if @controller.createdAccounts.length}}
          <div class="created-accounts-summary">
            <h3>📋 New Account Login Details</h3>
            <p class="field-help">Please save these details — the passwords cannot be retrieved later.</p>
            <table class="family-accounts-table">
              <thead>
                <tr>
                  <th>Username</th>
                  <th>Password</th>
                </tr>
              </thead>
              <tbody>
                {{#each @controller.createdAccounts as |account|}}
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
          <div class="family-summary-table">
            <h3>👨‍👩‍👧 Family Members</h3>
            <table class="family-accounts-table">
              <thead>
                <tr>
                  <th>Username</th>
                  <th>Name</th>
                  <th>Date of Birth</th>
                  <th>BRCA Number</th>
                </tr>
              </thead>
              <tbody>
                {{#each @controller.familyMembers as |member|}}
                  <tr>
                    <td>{{member.username}}</td>
                    <td>{{member.name}}</td>
                    <td>{{member.date_of_birth}}</td>
                    <td>{{member.brca_membership_number}}</td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          </div>
        {{/if}}

        <div class="booking-success-actions">
          <button class="btn btn-primary" type="button" {{on "click" @controller.goToMemberships}}>
            🎫 Go to My Memberships
          </button>
        </div>
      </div>
    {{else}}
      <h1>👨‍👩‍👧 Set Up Family Members</h1>
      <p>Your family membership for <strong>{{@controller.model.organisation_name}}</strong> allows up to <strong>{{@controller.model.max_members}}</strong> members (including you).</p>
      <p class="field-help">Add up to {{@controller.availableSlots}} additional family members below. You can search for existing users or create new accounts.</p>

      {{#if @controller.errorMessage}}
        <div class="alert alert-error family-error">{{@controller.errorMessage}}</div>
      {{/if}}

      {{#if @controller.familyMembers.length}}
        <div class="family-current-members">
          <h3>Current Family Members</h3>
          {{#each @controller.familyMembers as |member|}}
            <div class="family-member-row">
              <div class="family-member-info">
                {{#if member.avatar_url}}
                  <img alt="" class="user-avatar" src={{member.avatar_url}} />
                {{/if}}
                <span class="user-username">{{member.username}}</span>
                {{#if member.name}}<span class="user-name">— {{member.name}}</span>{{/if}}
                {{#if member.date_of_birth}}<span class="member-detail">DOB: {{member.date_of_birth}}</span>{{/if}}
                {{#if member.brca_membership_number}}<span class="member-detail">BRCA: {{member.brca_membership_number}}</span>{{/if}}
              </div>
              <button class="btn btn-small btn-danger" type="button" {{on "click" (fn @controller.removeMember member)}}>Remove</button>
            </div>
          {{/each}}
        </div>
      {{/if}}

      {{#if @controller.canAddMore}}
        <div class="family-add-section">
          <h3>Add Family Member</h3>

          <div class="family-search-box">
            <label>Search for existing user:</label>
            <input
              class="family-search-input"
              placeholder="Type username or name to search..."
              type="text"
              value={{@controller.searchTerm}}
              {{on "input" @controller.onSearchInput}}
            />
          </div>

          {{#if @controller.searchResults.length}}
            <div class="family-search-results">
              {{#each @controller.searchResults as |user|}}
                <div class="family-search-result" role="button" {{on "click" (fn @controller.selectExistingUser user)}}>
                  {{#if user.avatar_template}}
                    <img alt="" class="user-avatar" src={{user.avatar_template}} />
                  {{/if}}
                  <span class="user-username">{{user.username}}</span>
                  {{#if user.name}}<span class="user-name">— {{user.name}}</span>{{/if}}
                </div>
              {{/each}}
            </div>
          {{/if}}

          {{#if @controller.addingMember}}
            <div class="family-loading">Adding member...</div>
          {{/if}}

          <div class="family-or-divider">
            <span>— OR —</span>
          </div>

          <button class="btn btn-default" type="button" {{on "click" @controller.toggleCreateForm}}>
            {{#if @controller.showCreateForm}}Hide Create Form{{else}}➕ Create New Account{{/if}}
          </button>

          {{#if @controller.showCreateForm}}
            <div class="family-create-form">
              <div class="family-form-field">
                <label>Username <span class="required">*</span></label>
                <input placeholder="username" type="text" value={{@controller.newUsername}} {{on "input" @controller.setNewUsername}} />
              </div>
              <div class="family-form-field">
                <label>Full Name <span class="required">*</span></label>
                <input placeholder="Full Name" type="text" value={{@controller.newName}} {{on "input" @controller.setNewName}} />
              </div>
              <div class="family-form-field">
                <label>Date of Birth <span class="required">*</span></label>
                <input type="date" value={{@controller.newDob}} {{on "input" @controller.setNewDob}} />
              </div>
              <div class="family-form-field">
                <label>BRCA Number</label>
                <input placeholder="Optional" type="text" value={{@controller.newBrca}} {{on "input" @controller.setNewBrca}} />
              </div>
              <div class="family-form-field">
                <label>Email</label>
                <input placeholder="Optional — auto-generated if blank" type="email" value={{@controller.newEmail}} {{on "input" @controller.setNewEmail}} />
              </div>
              <button class="btn btn-primary" disabled={{@controller.creatingUser}} type="button"
                {{on "click" @controller.createAndAddUser}}>
                {{#if @controller.creatingUser}}Creating...{{else}}Create & Add Member{{/if}}
              </button>
            </div>
          {{/if}}
        </div>
      {{/if}}

      <div class="family-setup-actions">
        <button class="btn btn-primary btn-large" type="button" {{on "click" @controller.finishSetup}}>
          ✅ Done — View Summary
        </button>
      </div>
    {{/if}}
  </div>
</template>
