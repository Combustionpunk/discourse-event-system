import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class RacingProfileController extends Controller {
  @service router;
  @tracked isSaving = false;
  @tracked successMessage = null;
  @tracked dateOfBirth = "";
  @tracked brcaNumber = "";

  // Family members
  @tracked familyMembers = [];
  @tracked familySearchTerm = "";
  @tracked familySearchResults = [];
  @tracked selectedFamilyUser = null;
  @tracked searchTimeout = null;
  @tracked showCreateFamily = false;
  @tracked newFamUsername = "";
  @tracked newFamName = "";
  @tracked newFamDob = "";
  @tracked newFamBrca = "";
  @tracked newFamEmail = "";
  @tracked familyCreating = false;
  @tracked familyAdding = false;
  @tracked familyError = null;
  @tracked createdFamilyAccounts = [];
  @tracked editingFamilyId = null;
  @tracked editFamDob = "";
  @tracked editFamBrca = "";

  setup() {
    this.loadFamilyMembers();
  }

  async loadFamilyMembers() {
    try {
      const response = await ajax("/des/racing-profile/family-members.json");
      this.familyMembers = response.family_members || [];
    } catch {
      this.familyMembers = [];
    }
  }

  @action setDateOfBirth(event) { this.dateOfBirth = event.target.value; }
  @action setBrcaNumber(event) { this.brcaNumber = event.target.value; }

  @action
  async saveProfile() {
    this.isSaving = true;
    this.successMessage = null;
    try {
      await ajax("/des/racing-profile.json", {
        type: "PUT",
        data: {
          date_of_birth: this.dateOfBirth || this.model.profile.user.date_of_birth,
          brca_membership_number: this.brcaNumber || this.model.profile.user.brca_membership_number,
        },
      });
      this.successMessage = "Profile saved successfully!";
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  // Family member actions
  @action
  async updateFamilySearch(e) {
    const term = e.target.value;
    this.familySearchTerm = term;
    if (!term || term.length < 2) {
      this.familySearchResults = [];
      return;
    }
    try {
      const response = await ajax("/users/search.json?term=" + encodeURIComponent(term) + "&include_staged_users=false");
      if (this.familySearchTerm === term) {
        this.familySearchResults = response.users || [];
      }
    } catch (err) {
      this.familySearchResults = [];
    }
  }

  @action
  selectFamilyUser(user) {
    this.selectedFamilyUser = user;
    this.familySearchTerm = user.username;
    this.familySearchResults = [];
  }

  @action
  clearSelectedFamilyUser() {
    this.selectedFamilyUser = null;
    this.familySearchTerm = "";
  }

  @action
  async confirmAddFamilyUser() {
    if (!this.selectedFamilyUser) return;
    this.familyError = null;
    this.familyAdding = true;
    try {
      const response = await ajax("/des/racing-profile/family-members.json", {
        type: "POST",
        data: { username: this.selectedFamilyUser.username }
      });
      this.familyMembers = [...this.familyMembers, response.user];
      this.selectedFamilyUser = null;
      this.familySearchTerm = "";
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to add member";
    }
    this.familyAdding = false;
  }

  @action toggleCreateFamily() {
    this.showCreateFamily = !this.showCreateFamily;
    this.newFamUsername = ""; this.newFamName = ""; this.newFamDob = "";
    this.newFamBrca = ""; this.newFamEmail = "";
  }

  @action setNewFamUsername(e) { this.newFamUsername = e.target.value; }
  @action setNewFamName(e) { this.newFamName = e.target.value; }
  @action setNewFamDob(e) { this.newFamDob = e.target.value; }
  @action setNewFamBrca(e) { this.newFamBrca = e.target.value; }
  @action setNewFamEmail(e) { this.newFamEmail = e.target.value; }
  @action setEditFamDob(e) { this.editFamDob = e.target.value; }
  @action setEditFamBrca(e) { this.editFamBrca = e.target.value; }

  @action
  async createFamilyUser() {
    if (!this.newFamUsername || !this.newFamName || !this.newFamDob) {
      this.familyError = "Username, full name, and date of birth are required";
      return;
    }
    this.familyError = null;
    this.familyCreating = true;
    try {
      const response = await ajax("/des/racing-profile/family-members.json", {
        type: "POST",
        data: {
          create_user: true,
          username: this.newFamUsername,
          name: this.newFamName,
          email: this.newFamEmail,
          date_of_birth: this.newFamDob,
          brca_membership_number: this.newFamBrca
        }
      });
      this.familyMembers = [...this.familyMembers, response.user];
      if (response.created && response.password) {
        this.createdFamilyAccounts = [...this.createdFamilyAccounts, {
          username: response.user.username,
          password: response.password
        }];
      }
      this.showCreateFamily = false;
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to create user";
    }
    this.familyCreating = false;
  }

  @action
  async removeFamilyMember(member) {
    if (!confirm(`Remove ${member.username} from family members?`)) return;
    try {
      await ajax(`/des/racing-profile/family-members/${member.user_id}.json`, { type: "DELETE" });
      this.familyMembers = this.familyMembers.filter(m => m.user_id !== member.user_id);
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to remove member";
    }
  }

  @action
  startEditFamily(member) {
    this.editingFamilyId = member.user_id;
    this.editFamDob = member.date_of_birth || "";
    this.editFamBrca = member.brca_membership_number || "";
  }

  @action cancelEditFamily() { this.editingFamilyId = null; }

  @action
  async saveEditFamily(member) {
    this.familyError = null;
    try {
      const response = await ajax(`/des/racing-profile/family-members/${member.user_id}.json`, {
        type: "PUT",
        data: { date_of_birth: this.editFamDob, brca_membership_number: this.editFamBrca }
      });
      this.familyMembers = this.familyMembers.map(m =>
        m.user_id === member.user_id ? response.user : m
      );
      this.editingFamilyId = null;
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to update member";
    }
  }
}
