import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class EventsRoute extends Route {
  model() {
    return ajax("/des/events.json").then((response) => {
      return response.events.map((event) => {
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
    });
  }
}
