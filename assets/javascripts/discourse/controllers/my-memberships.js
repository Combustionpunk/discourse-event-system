import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

export default class MyMembershipsController extends Controller {
  @service router;

  @tracked expandedFamilyId = null;
  @tracked familySearchTerm = "";
  @tracked familySearchResults = [];
  @tracked showFamilyCreateForm = false;
  @tracked familyNewUsername = "";
  @tracked familyNewName = "";
  @tracked familyNewEmail = "";
  @tracked familyNewDob = "";
  @tracked familyNewBrca = "";
  @tracked familyCreatingUser = false;
  @tracked familyAddingMember = false;
  @tracked familyError = null;
  @tracked editingMemberId = null;
  @tracked editDob = "";
  @tracked editBrca = "";
  @tracked familyCreatedAccounts = [];

  formatDate(dateStr) {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleDateString("en-GB", {
      day: "numeric",
      month: "short",
      year: "numeric",
    });
  }

  isExpiringSoon(dateStr) {
    if (!dateStr) return false;
    const expires = new Date(dateStr);
    const soon = new Date();
    soon.setDate(soon.getDate() + 30);
    return expires < soon && expires > new Date();
  }

  @action
  toggleFamilyPanel(membershipId) {
    if (this.expandedFamilyId === membershipId) {
      this.expandedFamilyId = null;
    } else {
      this.expandedFamilyId = membershipId;
      this.familyError = null;
      this.familySearchTerm = "";
      this.familySearchResults = [];
      this.showFamilyCreateForm = false;
      this.editingMemberId = null;
      this.familyCreatedAccounts = [];
    }
  }

  @action
  async onFamilySearch(event) {
    const term = event.target.value;
    this.familySearchTerm = term;
    if (!term || term.length < 2) {
      this.familySearchResults = [];
      return;
    }
    try {
      const results = await ajax(`/users/search.json?term=${encodeURIComponent(term)}`);
      this.familySearchResults = (results.users || results || []).slice(0, 8);
    } catch {
      this.familySearchResults = [];
    }
  }

  @action
  async selectFamilyUser(membership, user) {
    this.familySearchResults = [];
    this.familySearchTerm = "";
    this.familyError = null;
    this.familyAddingMember = true;
    try {
      const response = await ajax(`/des/memberships/${membership.id}/family-members.json`, {
        type: "POST",
        data: { username: user.username }
      });
      membership.family_members = [...(membership.family_members || []), response.user];
      membership.family_members_count = membership.family_members.length;
      this.model = { ...this.model };
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to add member";
    }
    this.familyAddingMember = false;
  }

  @action
  toggleFamilyCreateForm() {
    this.showFamilyCreateForm = !this.showFamilyCreateForm;
    if (this.showFamilyCreateForm) {
      this.familyNewUsername = "";
      this.familyNewName = "";
      this.familyNewEmail = "";
      this.familyNewDob = "";
      this.familyNewBrca = "";
    }
  }

  @action setFamilyNewUsername(e) { this.familyNewUsername = e.target.value; }
  @action setFamilyNewName(e) { this.familyNewName = e.target.value; }
  @action setFamilyNewEmail(e) { this.familyNewEmail = e.target.value; }
  @action setFamilyNewDob(e) { this.familyNewDob = e.target.value; }
  @action setFamilyNewBrca(e) { this.familyNewBrca = e.target.value; }
  @action setEditDob(e) { this.editDob = e.target.value; }
  @action setEditBrca(e) { this.editBrca = e.target.value; }

  @action
  async createFamilyUser(membership) {
    if (!this.familyNewUsername || !this.familyNewName || !this.familyNewDob) {
      this.familyError = "Username, full name, and date of birth are required";
      return;
    }
    this.familyError = null;
    this.familyCreatingUser = true;
    try {
      const response = await ajax(`/des/memberships/${membership.id}/family-members.json`, {
        type: "POST",
        data: {
          create_user: true,
          username: this.familyNewUsername,
          name: this.familyNewName,
          email: this.familyNewEmail,
          date_of_birth: this.familyNewDob,
          brca_membership_number: this.familyNewBrca
        }
      });
      membership.family_members = [...(membership.family_members || []), response.user];
      membership.family_members_count = membership.family_members.length;
      if (response.created && response.password) {
        this.familyCreatedAccounts = [...this.familyCreatedAccounts, {
          username: response.user.username,
          password: response.password
        }];
      }
      this.showFamilyCreateForm = false;
      this.model = { ...this.model };
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to create user";
    }
    this.familyCreatingUser = false;
  }

  @action
  async removeFamilyMember(membership, member) {
    if (!confirm(`Remove ${member.username} from family membership?`)) return;
    this.familyError = null;
    try {
      await ajax(`/des/memberships/${membership.id}/family-members/${member.user_id}.json`, {
        type: "DELETE"
      });
      membership.family_members = (membership.family_members || []).filter(m => m.user_id !== member.user_id);
      membership.family_members_count = membership.family_members.length;
      this.model = { ...this.model };
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to remove member";
    }
  }

  @action
  startEditMember(member) {
    this.editingMemberId = member.user_id;
    this.editDob = member.date_of_birth || "";
    this.editBrca = member.brca_membership_number || "";
  }

  @action
  cancelEditMember() {
    this.editingMemberId = null;
  }

  @action
  async saveEditMember(membership, member) {
    this.familyError = null;
    try {
      const response = await ajax(`/des/memberships/${membership.id}/family-members/${member.user_id}.json`, {
        type: "PUT",
        data: {
          date_of_birth: this.editDob,
          brca_membership_number: this.editBrca
        }
      });
      member.date_of_birth = response.date_of_birth;
      member.brca_membership_number = response.brca_membership_number;
      this.editingMemberId = null;
      this.model = { ...this.model };
    } catch (e) {
      this.familyError = e.jqXHR?.responseJSON?.error || "Failed to update member";
    }
  }

  canAddMoreFamily(membership) {
    const used = (membership.family_members || []).length;
    const max = (membership.max_members || 1) - 1;
    return used < max;
  }
}
