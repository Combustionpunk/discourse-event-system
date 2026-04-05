import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class MyMembershipsRoute extends Route {
  async model() {
    const data = await ajax("/des/my-memberships.json");
    return { memberships: data.memberships || [] };
  }
}
