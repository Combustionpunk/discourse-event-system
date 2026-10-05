import { LinkTo } from "@ember/routing";

// Members follow an event to its RC Meetings topic; topic-less events (drafts) use the back office.
const DesEventLink = <template>
  {{#if @event.topic_url}}
    <a href={{@event.topic_url}} ...attributes>{{yield}}</a>
  {{else}}
    <LinkTo ...attributes @model={{@event.id}} @route="event">{{yield}}</LinkTo>
  {{/if}}
</template>;

export default DesEventLink;
