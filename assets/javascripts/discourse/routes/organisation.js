import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class OrganisationRoute extends Route {
  model(params) {
    return ajax("/des/organisations/" + params.organisation_id + ".json");
  }
}
