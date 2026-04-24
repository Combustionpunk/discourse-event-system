import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
export default class VenuesRoute extends Route {
  async model() {
    const venuesData = await ajax("/des/venues.json");
    let myOrgs = [];
    try {
      const orgsData = await ajax("/des/my-organisations.json");
      myOrgs = orgsData.organisations || [];
    } catch {}
    return { venues: venuesData.venues || [], myOrgs };
  }
}
