import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class RacingProfileRoute extends Route {
  model() {
    return ajax("/des/racing-profile.json");
  }
}
