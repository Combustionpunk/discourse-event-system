import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class MyGarageRoute extends Route {
  model() {
    return ajax("/des/garage.json");
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.loadUserTransponders();
  }
}
