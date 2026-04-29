import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class CarModelsRoute extends Route {
  async model() {
    return ajax("/des/car-models.json");
  }
}
