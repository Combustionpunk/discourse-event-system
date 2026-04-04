import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";

export default class OrganisationNewController extends Controller {
  @tracked isSaving = false;
  @tracked successMessage = null;

  @action
  async saveOrganisation(event) {
    event.preventDefault();
    this.isSaving = true;

    try {
      await ajax("/des/organisations.json", {
        type: "POST",
        data: {
          organisation: {
            name: this.model.name,
            description: this.model.description,
            email: this.model.email,
            phone: this.model.phone,
            website: this.model.website,
            address: this.model.address,
            google_maps_url: this.model.google_maps_url,
            paypal_email: this.model.paypal_email,
          },
        },
      });

      this.successMessage = "Organisation submitted successfully! An admin will review your application.";
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }

  @action
  updateField(field, event) {
    this.model[field] = event.target.value;
  }
}
