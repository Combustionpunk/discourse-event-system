import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
export default class VenuesRoute extends Route {
  async model() {
    return await ajax("/des/venues.json");
  }
}
