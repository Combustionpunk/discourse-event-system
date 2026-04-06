import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";

export default class EventsController extends Controller {
  @service router;

  queryParams = ["filter", "organisation_id", "event_type_id"];

  @tracked filter = "upcoming";
  @tracked organisation_id = null;
  @tracked event_type_id = null;

  get isUpcoming() {
    return this.filter !== "past";
  }

  @action
  setFilter(value) {
    this.filter = value;
  }

  @action
  setOrganisation(e) {
    this.organisation_id = e.target.value || null;
  }

  @action
  setEventType(e) {
    this.event_type_id = e.target.value || null;
  }

  @action
  clearFilters() {
    this.filter = "upcoming";
    this.organisation_id = null;
    this.event_type_id = null;
  }
}
