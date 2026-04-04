import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class OrganisationController extends Controller {
  @service router;
  @tracked showAddMember = false;
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
