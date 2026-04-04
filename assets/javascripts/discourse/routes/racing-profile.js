import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class RacingProfileRoute extends Route {
  async model() {
    const [profile, garage] = await Promise.all([
      ajax("/des/racing-profile.json"),
      ajax("/des/garage.json"),
    ]);
    return { profile, garage };
  }
}
