import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class EventManageRoute extends Route {
  async model(params) {
    const event = await ajax("/des/events/" + params.event_id + ".json");
    const entrants = await ajax("/des/events/" + params.event_id + "/entrants.json");

    const formatDate = (dateStr) => {
      if (!dateStr) return null;
      return new Date(dateStr).toLocaleDateString("en-GB", {
        weekday: "long", year: "numeric", month: "long",
        day: "numeric", hour: "2-digit", minute: "2-digit"
      });
    };

    event.formatted_start_date = formatDate(event.start_date);
    event.formatted_end_date = formatDate(event.end_date);
    event.formatted_booking_closing_date = formatDate(event.booking_closing_date);

    // Format for datetime-local inputs (YYYY-MM-DDTHH:MM)
    const toInputFormat = (dateStr) => {
      if (!dateStr) return "";
      const d = new Date(dateStr);
      const pad = (n) => String(n).padStart(2, "0");
      return d.getFullYear() + "-" + pad(d.getMonth()+1) + "-" + pad(d.getDate()) +
             "T" + pad(d.getHours()) + ":" + pad(d.getMinutes());
    };
    event.start_date = toInputFormat(event.start_date);
    event.end_date = toInputFormat(event.end_date);
    event.booking_closing_date = toInputFormat(event.booking_closing_date);

    return { event, entrants };
  }
}
