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
      const statusOrder = { confirmed: 0, pending: 1, waitlist: 2, cancelled: 3 };
      event.public_entrants = (entrantsData.classes || []).map(cls => {
        const sorted = (cls.entrants || []).slice().sort((a, b) => {
          const sa = statusOrder[a.status] ?? 99;
          const sb = statusOrder[b.status] ?? 99;
          if (sa !== sb) return sa - sb;
          return a.username.localeCompare(b.username);
        });
        return {
          id: cls.id,
          name: cls.name,
          entrants: sorted
        };
      });
    } catch {
      event.public_entrants = [];
    }

    // Load topic posts if event has a linked topic
    if (event.topic_id) {
      try {
        const topic = await ajax(`/t/${event.topic_id}.json`);
        event.topic_posts = (topic.post_stream?.posts || []).map(p => ({
          id: p.id,
          username: p.username,
          avatar_template: p.avatar_template?.replace("{size}", "45"),
          cooked: p.cooked,
          created_at: p.created_at,
          post_number: p.post_number,
          reply_count: p.reply_count,
          like_count: p.actions_summary?.find(a => a.id === 2)?.count || 0
        }));
        event.topic_posts_count = topic.posts_count || 0;
        event.topic_reply_url = `/t/${event.topic_slug}/${event.topic_id}`;
      } catch {
        event.topic_posts = [];
      }
    }

    return event;
  }
}
