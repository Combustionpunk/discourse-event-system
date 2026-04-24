import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class VenuesController extends Controller {
  @service router;
  @tracked showForm = false;
  @tracked isSaving = false;
  @tracked newVenue = {};

  trackCategories = ["onroad", "offroad"];
  trackSurfaces = ["carpet", "astroturf", "grass", "tarmac", "mixed"];
  trackEnvironments = ["outdoor", "indoor_covered"];

  get canSuggest() {
    return this.model.myOrgs && this.model.myOrgs.length > 0;
  }

  @action toggleForm() {
    this.showForm = !this.showForm;
    if (this.showForm) {
      this.newVenue = {
        name: "", address: "", google_maps_url: "", track_category: "",
        track_surface: "", track_environment: "", website: "", description: "",
        parking_info: "", local_facilities: "", access_notes: "",
        created_by_organisation_id: this.model.myOrgs[0]?.id || "",
        has_portaloos: false, has_permanent_toilets: false, has_bar: false,
        has_showers: false, has_power_supply: false, has_water_supply: false, has_camping: false,
      };
    }
  }

  @action updateField(field, e) {
    this.newVenue = { ...this.newVenue, [field]: e.target.value };
  }

  @action toggleFacility(field) {
    this.newVenue = { ...this.newVenue, [field]: !this.newVenue[field] };
  }

  @action
  async saveVenue() {
    if (!this.newVenue.name) { alert("Name is required"); return; }
    this.isSaving = true;
    try {
      await ajax("/des/venues.json", { type: "POST", data: this.newVenue });
      this.showForm = false;
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.isSaving = false;
    }
  }
}
