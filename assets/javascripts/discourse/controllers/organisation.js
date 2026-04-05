import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
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
  showMembers() { this.activeTab = "members"; }

  @action
  showEvents() { this.activeTab = "events"; }

  @action
  showRules() { this.activeTab = "rules"; }

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
