import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class EventRoute extends Route {
  async model(params) {
    const event = await ajax(`/des/events/${params.event_id}.json`);
    const date = new Date(event.start_date);
    event.formatted_date = date.toLocaleDateString("en-GB", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });

    try {
      const entrantsData = await ajax(`/des/events/${params.event_id}/public-entrants.json`);
      event.public_entrants = entrantsData.classes || [];
    } catch {
      event.public_entrants = [];
    }

    return event;
  }
}
