import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class OrganisationsRoute extends Route {
  model() {
    return ajax("/des/organisations.json").then((response) => {
      return response.organisations || response;
    });
  }
}
