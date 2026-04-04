import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class DesAdminRoute extends Route {
  model() {
    return ajax("/des/admin.json");
  }
}
