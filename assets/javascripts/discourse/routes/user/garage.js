import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class UserGarageRoute extends Route {
  templateName = "user/garage";

  async model() {
    const user = this.modelFor("user");
    try {
      const response = await ajax(`/des/garage/${user.username}/public.json`);
      return { cars: response.cars || [], username: user.username };
    } catch {
      return { cars: [], username: user.username };
    }
  }
}
