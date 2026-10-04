import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class CarModelRoute extends Route {
  // The segment is "<id>-<slug>"; only the id matters.
  model(params) {
    return ajax(`/des/car-models/${parseInt(params.car_model_id, 10)}.json`);
  }

  titleToken() {
    const { model } = this.currentModel;
    return [model.manufacturer_name, model.name].filter(Boolean).join(" ");
  }
}
