import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";

export default apiInitializer("1.0", (api) => {
  api.decorateCooked(
    (elem, helper) => {
      if (!helper) return;
      const post = helper.getModel();
      if (!post || post.post_number !== 1) return;
      const topicId = post.topic?.id;
      if (!topicId) return;

      ajax("/des/events/by-topic/" + topicId + ".json")
        .then((event) => {
          if (!event?.id) return;

          const div = document.createElement("div");
          div.className = "event-booking-widget-cooked";
          div.innerHTML = `
            <div class="event-booking-widget-header">
              <h3>🏁 Book Your Place</h3>
            </div>
            <div class="event-classes-booking">
              ${event.classes.map(cls => `
                <div class="event-class-booking-row">
                  <div class="event-class-booking-info">
                    <strong>${cls.name}</strong>
                    <span class="spaces-badge">${cls.spaces_remaining} / ${cls.capacity} spaces</span>
                  </div>
                </div>
              `).join("")}
            </div>
            <a href="/events/${event.id}" class="btn btn-primary event-book-btn" style="margin-top:12px; display:inline-block;">
              🎟️ Book Now
            </a>
          `;
          elem[0].appendChild(div);
        })
        .catch(() => {});
    },
    { onlyStream: true, id: "des-event-booking" }
  );
});
