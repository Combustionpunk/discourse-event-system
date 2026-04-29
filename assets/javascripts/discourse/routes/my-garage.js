import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class MyGarageRoute extends Route {
  queryParams = {
    manufacturer_id: { refreshModel: false },
    model_id: { refreshModel: false }
  };

  async model() {
    return ajax("/des/garage.json");
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.loadUserTransponders();
    setTimeout(() => controller.checkQueryParams(), 100);
  }
}
