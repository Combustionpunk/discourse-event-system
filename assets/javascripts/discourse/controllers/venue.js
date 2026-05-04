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
  @tracked showClaimForm = false;
  @tracked selectedClaimOrgId = null;

  @action toggleEdit() {
    this.editMode = !this.editMode;
    this.suggestMode = false;
    this.showClaimForm = false;
    if (this.editMode) {
      this.editData = { ...this.model.venue };
    }
  }

  @action toggleSuggest() {
    this.suggestMode = !this.suggestMode;
    this.editMode = false;
    this.showClaimForm = false;
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
    console.log('canClaim check:', this.currentUser, this.model?.myOrgs, this.model?.venue?.claim_status);
    if (!this.currentUser) return false;
    const venue = this.model.venue;
    if (venue.claim_status === 'approved' || venue.claim_status === 'pending') return false;
    return this.model.myOrgs?.length > 0;
  }

  @action
  toggleClaimForm() {
    this.showClaimForm = !this.showClaimForm;
    if (this.showClaimForm && this.model.myOrgs?.length === 1) {
      this.selectedClaimOrgId = this.model.myOrgs[0].id;
    }
  }

  @action
  updateSelectedClaimOrg(e) {
    this.selectedClaimOrgId = parseInt(e.target.value);
  }

  @action
  async submitClaim() {
    if (!this.selectedClaimOrgId) return;
    const org = this.model.myOrgs.find(o => o.id === this.selectedClaimOrgId);
    if (!window.confirm(`Claim this venue for ${org.name}?`)) return;
    try {
      await ajax(`/des/venues/${this.model.venue.id}/claim.json`, {
        type: "POST",
        data: { organisation_id: this.selectedClaimOrgId }
      });
      this.claimSent = true;
      this.showClaimForm = false;
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
