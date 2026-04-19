import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default class FamilySetupController extends Controller {
  @service router;

  @tracked searchResults = [];
  @tracked searching = false;
  @tracked showCreateForm = false;
  @tracked newUsername = "";
  @tracked newName = "";
  @tracked newEmail = "";
  @tracked newDob = "";
  @tracked newBrca = "";
  @tracked addingMember = false;
  @tracked creatingUser = false;
  @tracked createdAccounts = [];
  @tracked completed = false;
  @tracked errorMessage = null;
  @tracked searchTerm = "";
  @tracked familyMembers = [];

  setup(model) {
    this.familyMembers = model.family_members || [];
    this.completed = false;
    this.createdAccounts = [];
    this.errorMessage = null;
    this.searchTerm = "";
    this.searchResults = [];
    this.showCreateForm = false;
  }

  get availableSlots() {
    const used = this.familyMembers.length;
    const total = Math.max(0, (this.model.max_members || 1) - 1);
    return Math.max(0, total - used);
  }

  get canAddMore() {
    return this.availableSlots > 0;
  }

  @action
  async onSearchInput(event) {
    const term = event.target.value;
    this.searchTerm = term;
    if (!term || term.length < 2) {
      this.searchResults = [];
      return;
    }
    this.searching = true;
    try {
      const results = await ajax(`/users/search.json?term=${encodeURIComponent(term)}`);
      this.searchResults = (results.users || results || []).slice(0, 8);
    } catch {
      this.searchResults = [];
    }
    this.searching = false;
  }

  @action
  toggleCreateForm() {
    this.showCreateForm = !this.showCreateForm;
    if (this.showCreateForm) {
      this.newUsername = "";
      this.newName = "";
      this.newEmail = "";
      this.newDob = "";
      this.newBrca = "";
    }
  }

  @action setNewUsername(e) { this.newUsername = e.target.value; }
  @action setNewName(e) { this.newName = e.target.value; }
  @action setNewEmail(e) { this.newEmail = e.target.value; }
  @action setNewDob(e) { this.newDob = e.target.value; }
  @action setNewBrca(e) { this.newBrca = e.target.value; }

  @action
  async selectExistingUser(user) {
    this.searchResults = [];
    this.searchTerm = "";
    this.errorMessage = null;
    this.addingMember = true;
    try {
      const response = await ajax(`/des/memberships/${this.model.membership_id}/family-members.json`, {
        type: "POST",
        data: { username: user.username }
      });
      this.familyMembers = [...this.familyMembers, response.user];
    } catch (e) {
      this.errorMessage = e.jqXHR?.responseJSON?.error || "Failed to add member";
    }
    this.addingMember = false;
  }

  @action
  async createAndAddUser() {
    if (!this.newUsername || !this.newName || !this.newDob) {
      this.errorMessage = "Username, full name, and date of birth are required";
      return;
    }
    this.errorMessage = null;
    this.creatingUser = true;
    try {
      const response = await ajax(`/des/memberships/${this.model.membership_id}/family-members.json`, {
        type: "POST",
        data: {
          create_user: true,
          username: this.newUsername,
          name: this.newName,
          email: this.newEmail,
          date_of_birth: this.newDob,
          brca_membership_number: this.newBrca
        }
      });
      this.familyMembers = [...this.familyMembers, response.user];
      if (response.created && response.password) {
        this.createdAccounts = [...this.createdAccounts, {
          username: response.user.username,
          password: response.password
        }];
      }
      this.showCreateForm = false;
      this.newUsername = "";
      this.newName = "";
      this.newEmail = "";
      this.newDob = "";
      this.newBrca = "";
    } catch (e) {
      this.errorMessage = e.jqXHR?.responseJSON?.error || "Failed to create user";
    }
    this.creatingUser = false;
  }

  @action
  async removeMember(member) {
    if (!confirm(`Remove ${member.username} from family membership?`)) return;
    try {
      await ajax(`/des/memberships/${this.model.membership_id}/family-members/${member.user_id}.json`, {
        type: "DELETE"
      });
      this.familyMembers = this.familyMembers.filter(m => m.user_id !== member.user_id);
    } catch (e) {
      this.errorMessage = e.jqXHR?.responseJSON?.error || "Failed to remove member";
    }
  }

  @action
  finishSetup() {
    this.completed = true;
  }

  @action
  goToMemberships() {
    this.router.transitionTo("my-memberships");
  }
}
