import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class VenueController extends Controller {
  @service router;
  @service currentUser;
  @tracked editMode = false;
  @tracked editData = {};
  @tracked isSaving = false;
  @tracked suggestMode = false;
  @tracked suggestData = {};
  @tracked suggestionSent = false;
  @tracked claimSent = false;

  @action toggleEdit() {
    this.editMode = !this.editMode;
    this.suggestMode = false;
    if (this.editMode) {
      this.editData = { ...this.model.venue };
    }
  }

  @action toggleSuggest() {
    this.suggestMode = !this.suggestMode;
    this.editMode = false;
    this.suggestionSent = false;
    if (this.suggestMode) {
      this.suggestData = { ...this.model.venue };
    }
  }

  @action
  async saveVenue(formData) {
    this.isSaving = true;
    try {
      await ajax("/des/venues/" + this.model.venue.id + ".json", {
        type: "PUT",
        data: formData
      });
      this.editMode = false;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  get canClaim() {
    if (!this.currentUser) return false;
    const venue = this.model.venue;
    if (venue.claim_status === 'approved' || venue.claim_status === 'pending') return false;
    return this.model.myOrgs?.length > 0;
  }

  @action
  async claimVenue() {
    if (!this.model.myOrgs?.length) return;
    const org = this.model.myOrgs[0];
    if (!window.confirm(`Claim this venue for ${org.name}?`)) return;
    try {
      await ajax(`/des/venues/${this.model.venue.id}/claim.json`, {
        type: "POST",
        data: { organisation_id: org.id }
      });
      this.claimSent = true;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async submitSuggestion(formData) {
    this.isSaving = true;
    try {
      await ajax(`/des/venues/${this.model.venue.id}/suggestions.json`, {
        type: "POST",
        data: { suggested_data: formData }
      });
      this.suggestionSent = true;
      this.suggestMode = false;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }
}
