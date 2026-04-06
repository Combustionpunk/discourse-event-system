import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class MyOrganisationsRoute extends Route {
  async model() {
    const data = await ajax("/des/my-organisations.json");
    return { organisations: data.organisations || [] };
  }
}
