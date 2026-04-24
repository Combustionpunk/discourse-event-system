import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
export default class VenueRoute extends Route {
  async model(params) {
    return await ajax("/des/venues/" + params.venue_id + ".json");
  }
}
