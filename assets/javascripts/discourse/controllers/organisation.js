import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { later } from "@ember/runloop";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class OrganisationController extends Controller {
  @service router;
  @tracked showAddMember = false;
  @tracked activeTab = "details";

  @action
  showTab(tab) {
    this.activeTab = tab;
  }

  @action
  showDetails() { this.activeTab = "details"; }

  @action
  showMembers() {
    this.activeTab = "members";
    this.loadAdminMemberships();
  }

  async loadAdminMemberships() {
    try {
      const response = await ajax("/des/organisations/" + this.model.id + "/admin-memberships.json");
      this.adminMemberships = response.memberships;
    } catch (e) {
      this.adminMemberships = [];
    }
  }

  @action
  toggleAddMembership() {
    this.showAddMembership = !this.showAddMembership;
  }

  get selectedMembershipType() {
    if (!this.newMembershipTypeId) return null;
    return (this.model.membership_types || []).find(
      t => String(t.id) === String(this.newMembershipTypeId)
    );
  }

  get selectedTypeIsFamily() {
    return this.selectedMembershipType?.is_family || false;
  }

  get selectedTypeMaxFamilyMembers() {
    const t = this.selectedMembershipType;
    return t ? (t.max_members || 1) - 1 : 0;
  }

  @action
  updateNewMembershipField(field, e) {
    if (field === "username") this.newMembershipUsername = e.target.value;
    else if (field === "membership_type_id") {
      this.newMembershipTypeId = e.target.value;
      this.newMembershipFamilyUsernames = [];
    }
    else if (field === "expires_at") this.newMembershipExpiresAt = e.target.value;
    else if (field === "amount_paid") this.newMembershipAmountPaid = e.target.value;
  }

  @action
  addFamilyUsernameField() {
    if (this.newMembershipFamilyUsernames.length < this.selectedTypeMaxFamilyMembers) {
      this.newMembershipFamilyUsernames = [...this.newMembershipFamilyUsernames, ""];
    }
  }

  @action
  updateFamilyUsername(index, e) {
    const updated = [...this.newMembershipFamilyUsernames];
    updated[index] = e.target.value;
    this.newMembershipFamilyUsernames = updated;
  }

  @action
  removeFamilyUsernameField(index) {
    const updated = [...this.newMembershipFamilyUsernames];
    updated.splice(index, 1);
    this.newMembershipFamilyUsernames = updated;
  }

  @action
  async saveAdminMembership() {
    try {
      const data = {
        username: this.newMembershipUsername,
        membership_type_id: this.newMembershipTypeId,
        expires_at: this.newMembershipExpiresAt,
        amount_paid: this.newMembershipAmountPaid,
      };

      // Include family usernames if any
      const familyNames = this.newMembershipFamilyUsernames.filter(u => u.trim());
      if (familyNames.length > 0) {
        const familyUsernames = {};
        familyNames.forEach((u, i) => { familyUsernames[i] = u; });
        data.family_usernames = familyUsernames;
      }

      await ajax("/des/organisations/" + this.model.id + "/admin-memberships.json", {
        type: "POST",
        data,
      });
      this.showAddMembership = false;
      this.newMembershipUsername = "";
      this.newMembershipTypeId = "";
      this.newMembershipExpiresAt = "";
      this.newMembershipAmountPaid = "";
      this.newMembershipFamilyUsernames = [];
      this.loadAdminMemberships();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  editMembership(m) {
    this.editingMembershipId = m.id;
    this.editingMembershipExpiry = m.expires_at ? m.expires_at.split('T')[0] : "";
  }

  @action
  updateEditingExpiry(e) {
    this.editingMembershipExpiry = e.target.value;
  }

  @action
  cancelEditMembership() {
    this.editingMembershipId = null;
    this.editingMembershipExpiry = "";
  }

  @action
  async saveEditMembership() {
    try {
      await ajax("/des/organisations/" + this.model.id + "/admin-memberships/" + this.editingMembershipId + ".json", {
        type: "PUT",
        data: { expires_at: this.editingMembershipExpiry },
      });
      this.editingMembershipId = null;
      this.loadAdminMemberships();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteMembership(m) {
    if (!window.confirm(`Permanently delete ${m.username}'s membership? This cannot be undone.`)) return;
    try {
      await ajax("/des/organisations/" + this.model.id + "/admin-memberships/" + m.id + ".json", {
        type: "DELETE",
      });
      this.loadAdminMemberships();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async changeMembershipStatus(m, event) {
    const newStatus = event.target.value;
    if (newStatus === m.status) return;
    try {
      await ajax("/des/organisations/" + this.model.id + "/admin-memberships/" + m.id + ".json", {
        type: "PUT",
        data: { status: newStatus },
      });
      this.loadAdminMemberships();
    } catch (error) {
      popupAjaxError(error);
    }
  }


  @action
  showEvents() { this.activeTab = "events"; }

  @action
  showRules() { this.activeTab = "rules"; }

  @tracked joiningMembershipTypeId = null;
  @tracked isFamilyMembership = false;
  @tracked maxFamilyMembers = 1;
  @tracked familyMemberUsernames = [];
  @tracked showFamilyModal = false;
  @tracked familyMemberSearch = "";
  @tracked familyUserSearchResults = [];

  @action
  showMemberships() { this.activeTab = "memberships"; }

  @action
  showSettings() {
    this.activeTab = "settings";
    this.settingsForm = {
      name: this.model.name,
      email: this.model.email || "",
      phone: this.model.phone || "",
      website: this.model.website || "",
      address: this.model.address || "",
      google_maps_url: this.model.google_maps_url || "",
      logo_url: this.model.logo_url || "",
      description: this.model.description || "",
    };
  }

  @action
  updateSettingsField(field, e) {
    this.settingsForm = { ...this.settingsForm, [field]: e.target.value };
  }

  @action
  async saveSettings() {
    try {
      await ajax("/des/organisations/" + this.model.id + ".json", {
        type: "PUT",
        data: { organisation: this.settingsForm },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  joinMembership(typeId, isFamily, maxMembers) {
    // Toggle off if already selected
    if (this.joiningMembershipTypeId === typeId) {
      this.cancelFamilyModal();
      return;
    }
    this.joiningMembershipTypeId = typeId;
    this.isFamilyMembership = isFamily;
    this.maxFamilyMembers = maxMembers;
    this.familyMemberUsernames = [];
    this.familyMemberSearch = "";
    if (!isFamily) {
      this.proceedWithJoin(typeId);
    }
  }

  @action
  addFamilyMemberToList() {
    const username = this.familyMemberSearch.trim();
    if (!username) return;
    if (this.familyMemberUsernames.includes(username)) {
      alert("Already added " + username);
      return;
    }
    if (this.familyMemberUsernames.length >= this.maxFamilyMembers - 1) {
      alert("Maximum family members reached");
      return;
    }
    this.familyMemberUsernames = [...this.familyMemberUsernames, username];
    this.familyMemberSearch = "";
    this.familyUserSearchResults = [];
  }

  @action
  removeFamilyMemberFromList(username) {
    this.familyMemberUsernames = this.familyMemberUsernames.filter(u => u !== username);
  }

  @action
  async updateFamilySearch(event) {
    this.familyMemberSearch = event.target.value;
    const query = this.familyMemberSearch.trim();
    if (query.length < 2) {
      this.familyUserSearchResults = [];
      return;
    }
    try {
      const response = await ajax("/u/search/users.json", {
        data: { term: query, include_groups: false }
      });
      this.familyUserSearchResults = (response.users || []).slice(0, 5).map(u => ({
        ...u,
        avatar_template: u.avatar_template.replace('{size}', '24')
      }));
    } catch (e) {
      this.familyUserSearchResults = [];
    }
  }

  @action
  selectFamilyUser(username) {
    this.familyMemberSearch = username;
    this.familyUserSearchResults = [];
    this.addFamilyMemberToList();
  }

  @action
  cancelFamilyModal() {
    this.showFamilyModal = false;
    this.joiningMembershipTypeId = null;
    this.familyMemberUsernames = [];
    this.familyMemberSearch = "";
    this.familyUserSearchResults = [];
  }

  @action
  async confirmFamilyJoin() {
    await this.proceedWithJoin(this.joiningMembershipTypeId, this.familyMemberUsernames);
    this.showFamilyModal = false;
  }

  async proceedWithJoin(typeId, familyUsernames = []) {
    try {
      const response = await ajax("/des/organisations/" + this.model.id + "/memberships.json", {
        type: "POST",
        data: {
          membership_type_id: typeId,
          family_usernames: familyUsernames
        },
      });
      if (response.free) {
        alert("You have successfully joined " + this.model.name + "!");
        this.router.refresh();
      } else {
        window.location.href = response.approval_url;
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async createMembershipType() {
    const name = document.getElementById('mtype-name').value.trim();
    const price = document.getElementById('mtype-price').value;
    const duration = document.getElementById('mtype-duration').value;
    const description = document.getElementById('mtype-desc').value.trim();
    const discount = document.getElementById('mtype-discount').value || 0;
    const maxMembers = document.getElementById('mtype-max-members').value || 1;
    const isFamily = parseInt(maxMembers) > 1;
    if (!name || !price || !duration) { alert("Please fill in name, price and duration."); return; }
    try {
      await ajax("/des/organisations/" + this.model.id + "/membership-types.json", {
        type: "POST",
        data: { name, price, duration_months: duration, description, discount_percentage: discount, max_members: maxMembers, is_family: isFamily },
      });
      document.getElementById('mtype-name').value = '';
      document.getElementById('mtype-price').value = '';
      document.getElementById('mtype-duration').value = '';
      document.getElementById('mtype-desc').value = '';
      document.getElementById('mtype-discount').value = '';
      document.getElementById('mtype-max-members').value = '1';
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteMembershipType(typeId) {
    if (!window.confirm("Remove this membership type?")) return;
    try {
      await ajax("/des/organisations/" + this.model.id + "/membership-types/" + typeId + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  get groupedOrgRules() {
    const rules = this.model.org_rules || [];
    const groups = {};
    rules.forEach(rule => {
      if (!groups[rule.class_type_id]) {
        groups[rule.class_type_id] = {
          class_type_name: rule.class_type_name,
          rules: []
        };
      }
      groups[rule.class_type_id].rules.push(rule);
    });
    return Object.values(groups);
  }

  @action
  async createClassType() {
    const name = document.getElementById('new-class-type-name').value.trim();
    const description = document.getElementById('new-class-type-desc').value.trim();
    if (!name) { alert("Please enter a class name."); return; }
    try {
      await ajax("/des/organisations/" + this.model.id + "/class-types.json", {
        type: "POST",
        data: { name, description },
      });
      document.getElementById('new-class-type-name').value = '';
      document.getElementById('new-class-type-desc').value = '';
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteClassType(classTypeId) {
    if (!window.confirm("Delete this class type and all its rules?")) return;
    try {
      await ajax("/des/organisations/" + this.model.id + "/class-types/" + classTypeId + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  ruleTypeLabel(ruleType) {
    const labels = {
      driveline: 'Driveline',
      chassis: 'Chassis',
      manufacturer: 'Manufacturer',
      max_year: 'Max Year',
      min_year: 'Min Year',
      max_age: 'Max Age',
      min_age: 'Min Age',
      model: 'Model'
    };
    return labels[ruleType] || ruleType;
  }

  get yearOptions() {
    const years = [];
    for (let y = new Date().getFullYear(); y >= 1970; y--) {
      years.push(y);
    }
    return years;
  }

  @action
  onRuleTypeChange(classTypeId) {
    const id = String(classTypeId);
    const typeSelect = document.querySelector('.rule-type-select[data-class-id="' + id + '"]');
    const ruleType = typeSelect?.value;

    // Hide all containers for this class
    document.querySelectorAll('.rule-value-container[data-class-id="' + id + '"]').forEach(el => {
      el.style.display = 'none';
    });

    // Show the relevant one
    if (ruleType === 'driveline') {
      document.querySelector('.rule-value-container--driveline[data-class-id="' + id + '"]').style.display = '';
    } else if (ruleType === 'chassis') {
      document.querySelector('.rule-value-container--chassis[data-class-id="' + id + '"]').style.display = '';
    } else if (ruleType === 'manufacturer') {
      document.querySelector('.rule-value-container--manufacturer[data-class-id="' + id + '"]').style.display = '';
    } else if (ruleType === 'max_year' || ruleType === 'min_year') {
      document.querySelector('.rule-value-container--year[data-class-id="' + id + '"]').style.display = '';
    } else if (ruleType === 'max_age' || ruleType === 'min_age') {
      document.querySelector('.rule-value-container--age[data-class-id="' + id + '"]').style.display = '';
    }
  }

  @action
  async addClassTypeRule(classTypeId) {
    const id = String(classTypeId);
    const typeSelect = document.querySelector('.rule-type-select[data-class-id="' + id + '"]');
    const ruleType = typeSelect?.value;
    let ruleValue = '';

    if (ruleType === 'driveline' || ruleType === 'chassis' || ruleType === 'manufacturer') {
      const multiSelect = document.querySelector('.rule-value-container[style=""] .rule-multiselect[data-class-id="' + id + '"], .rule-value-container:not([style*="none"]) .rule-multiselect[data-class-id="' + id + '"]');
      if (multiSelect) {
        const selected = Array.from(multiSelect.selectedOptions).map(o => o.value);
        ruleValue = selected.join(',');
      }
    } else if (ruleType === 'max_year' || ruleType === 'min_year') {
      const yearSelect = document.querySelector('.rule-year-select[data-class-id="' + id + '"]');
      ruleValue = yearSelect?.value;
    } else if (ruleType === 'max_age' || ruleType === 'min_age') {
      const ageInput = document.querySelector('.rule-age-input[data-class-id="' + id + '"]');
      ruleValue = ageInput?.value;
    }

    if (!ruleValue) { alert("Please select a value for the rule."); return; }

    try {
      await ajax("/des/organisations/" + this.model.id + "/class-types/" + classTypeId + "/rules.json", {
        type: "POST",
        data: { rule_type: ruleType, rule_value: ruleValue },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async deleteClassTypeRule(classTypeId, ruleId) {
    if (!window.confirm("Delete this rule?")) return;
    try {
      await ajax("/des/organisations/" + this.model.id + "/class-types/" + classTypeId + "/rules/" + ruleId + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
  @tracked newMemberUsername = "";
  @tracked userSearchResults = [];
  @tracked searchTimeout = null;
  @tracked newMemberPositionId = "";
  @tracked isSaving = false;
  @tracked settingsForm = {};
  @tracked showAddMembership = false;
  @tracked newMembershipUsername = "";
  @tracked newMembershipTypeId = "";
  @tracked newMembershipExpiresAt = "";
  @tracked newMembershipAmountPaid = "";
  @tracked adminMemberships = [];
  @tracked editingMembershipId = null;
  @tracked editingMembershipExpiry = "";
  @tracked newMembershipFamilyUsernames = [];
  @tracked managingFamilyMembershipId = null;
  @tracked newFamilyMemberUsername = "";
  @tracked newFamilyMemberDob = "";
  @tracked editingFamilyDobKey = null;
  @tracked editingFamilyDobValue = "";

  @action
  toggleManageFamily(membershipId) {
    if (this.managingFamilyMembershipId === membershipId) {
      this.managingFamilyMembershipId = null;
    } else {
      this.managingFamilyMembershipId = membershipId;
    }
    this.newFamilyMemberUsername = "";
    this.newFamilyMemberDob = "";
    this.editingFamilyDobKey = null;
    this.editingFamilyDobValue = "";
  }

  @action
  updateNewFamilyMemberUsername(e) {
    this.newFamilyMemberUsername = e.target.value;
  }

  @action
  updateNewFamilyMemberDob(e) {
    this.newFamilyMemberDob = e.target.value;
  }

  @action
  async addAdminFamilyMember(membershipId) {
    if (!this.newFamilyMemberUsername.trim()) return;
    try {
      const data = { username: this.newFamilyMemberUsername };
      if (this.newFamilyMemberDob) {
        data.date_of_birth = this.newFamilyMemberDob;
      }
      await ajax("/des/organisations/" + this.model.id + "/admin-memberships/" + membershipId + "/family.json", {
        type: "POST",
        data,
      });
      this.newFamilyMemberUsername = "";
      this.newFamilyMemberDob = "";
      this.loadAdminMemberships();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  startEditFamilyDob(membershipId, userId, currentDob) {
    this.editingFamilyDobKey = `${membershipId}_${userId}`;
    this.editingFamilyDobValue = currentDob || "";
  }

  @action
  updateEditingFamilyDob(e) {
    this.editingFamilyDobValue = e.target.value;
  }

  @action
  async saveEditFamilyDob(membershipId, userId) {
    try {
      await ajax("/des/organisations/" + this.model.id + "/admin-memberships/" + membershipId + "/family/" + userId + ".json", {
        type: "PUT",
        data: { date_of_birth: this.editingFamilyDobValue },
      });
      this.editingFamilyDobKey = null;
      this.editingFamilyDobValue = "";
      this.loadAdminMemberships();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  cancelEditFamilyDob() {
    this.editingFamilyDobKey = null;
    this.editingFamilyDobValue = "";
  }

  @action
  async removeAdminFamilyMember(membershipId, userId) {
    if (!window.confirm("Remove this family member?")) return;
    try {
      await ajax("/des/organisations/" + this.model.id + "/admin-memberships/" + membershipId + "/family/" + userId + ".json", {
        type: "DELETE",
      });
      this.loadAdminMemberships();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  toggleAddMember() {
    this.showAddMember = !this.showAddMember;
  }

  @action
  async updateUsername(event) {
    this.newMemberUsername = event.target.value;
    if (this.searchTimeout) clearTimeout(this.searchTimeout);
    if (this.newMemberUsername.length < 2) {
      this.userSearchResults = [];
      return;
    }
    this.searchTimeout = setTimeout(async () => {
      try {
        const response = await ajax("/u/search/users.json?term=" + this.newMemberUsername + "&include_staged_users=false");
        this.userSearchResults = response.users || [];
      } catch {
        this.userSearchResults = [];
      }
    }, 300);
  }

  @action
  selectUser(username) {
    this.newMemberUsername = username;
    this.userSearchResults = [];
  }

  @action
  updatePosition(event) {
    this.newMemberPositionId = event.target.value;
  }

  @action
  async addMember() {
    if (!this.newMemberUsername || !this.newMemberPositionId) {
      alert("Please enter a username and select a position");
      return;
    }
    this.isSaving = true;
    try {
      await ajax("/des/organisations/" + this.model.id + "/add_member.json", {
        type: "POST",
        data: {
          username: this.newMemberUsername,
          position_id: this.newMemberPositionId,
        },
      });
      this.showAddMember = false;
      this.newMemberUsername = "";
      this.newMemberPositionId = "";
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  async removeMember(memberId) {
    if (!window.confirm("Remove this member from the organisation?")) return;
    try {
      await ajax("/des/organisations/" + this.model.id + "/members/" + memberId + ".json", {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
