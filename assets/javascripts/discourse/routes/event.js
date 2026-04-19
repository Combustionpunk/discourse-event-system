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
      event.public_entrants = (entrantsData.classes || []).map(cls => {
        const confirmed = (cls.entrants || [])
          .filter(e => e.status === "confirmed")
          .sort((a, b) => a.username.localeCompare(b.username));
        const pending = (cls.entrants || [])
          .filter(e => e.status === "pending")
          .sort((a, b) => a.username.localeCompare(b.username));
        return {
          id: cls.id,
          name: cls.name,
          confirmed,
          pending,
          entrants: cls.entrants || []
        };
      });
    } catch {
      event.public_entrants = [];
    }

    return event;
  }
}
