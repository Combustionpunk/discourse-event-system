import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class VenueController extends Controller {
  @service router;
  @tracked editMode = false;
  @tracked editData = {};
  @tracked isSaving = false;

  @action toggleEdit() {
    this.editMode = !this.editMode;
    if (this.editMode) {
      this.editData = { ...this.model.venue };
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
}
