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

  @action
  setDateOfBirth(event) {
    this.dateOfBirth = event.target.value;
  }

  @action
  setBrcaNumber(event) {
    this.brcaNumber = event.target.value;
  }

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

  @action
  async removeCar(carId) {
    if (!window.confirm("Remove this car from your garage?")) return;
    try {
      await ajax("/des/garage/" + carId + ".json", { type: "DELETE" });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
