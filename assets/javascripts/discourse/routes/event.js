import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class EventRoute extends Route {
  model(params) {
    return ajax(`/des/events/${params.event_id}.json`).then((event) => {
      const date = new Date(event.start_date);
      event.formatted_date = date.toLocaleDateString("en-GB", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
      return event;
    });
  }
}
