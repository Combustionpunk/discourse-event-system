import Component from "@glimmer/component";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

// Link to the RC Meetings category, where members browse events.
export default class DesMeetingsLink extends Component {
  @service site;

  <template>
    <a href={{this.site.des_meetings_url}} ...attributes>
      {{#if (has-block)}}
        {{yield}}
      {{else}}
        {{i18n "discourse_event_system.nav.rc_meetings"}}
      {{/if}}
    </a>
  </template>
}
