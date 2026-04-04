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
  @tracked newTransponderClassId = "";
  @tracked newTransponderNumber = "";

  get availableClassTypes() {
    const existingClassTypeIds = this.model.transponders.map(
      (t) => t.class_type_id
    );
    return this.model.class_types.filter(
      (ct) => !existingClassTypeIds.includes(ct.id)
    );
  }

  @action
  setDateOfBirth(event) {
    this.dateOfBirth = event.target.value;
  }

  @action
  setBrcaNumber(event) {
    this.brcaNumber = event.target.value;
  }

  @action
  setNewTransponderClass(event) {
    this.newTransponderClassId = event.target.value;
  }

  @action
  setNewTransponderNumber(event) {
    this.newTransponderNumber = event.target.value;
  }

  @action
  async saveProfile() {
    this.isSaving = true;
    this.successMessage = null;

    try {
      await ajax("/des/racing-profile.json", {
        type: "PUT",
        data: {
          date_of_birth: this.dateOfBirth || this.model.user.date_of_birth,
          brca_membership_number: this.brcaNumber || this.model.user.brca_membership_number,
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
  async addTransponder() {
    if (!this.newTransponderClassId || !this.newTransponderNumber) return;

    try {
      await ajax("/des/racing-profile/transponders.json", {
        type: "POST",
        data: {
          class_type_id: this.newTransponderClassId,
          transponder_number: this.newTransponderNumber,
        },
      });
      this.newTransponderClassId = "";
      this.newTransponderNumber = "";
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  async removeTransponder(transponderId) {
    if (!window.confirm("Remove this transponder?")) return;

    try {
      await ajax(`/des/racing-profile/transponders/${transponderId}.json`, {
        type: "DELETE",
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }
}
