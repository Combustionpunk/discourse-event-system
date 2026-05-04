import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
export default class VenueRoute extends Route {
  async model(params) {
    const venueData = await ajax("/des/venues/" + params.venue_id + ".json");
    let myOrgs = [];
    try {
      const orgsData = await ajax("/des/my-organisations.json");
      myOrgs = orgsData.organisations || [];
    } catch { /* not logged in or no orgs */ }
    return { ...venueData, myOrgs };
  }
}
