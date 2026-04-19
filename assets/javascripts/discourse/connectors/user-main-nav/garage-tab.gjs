/* eslint-disable ember/no-classic-components */
import Component from "@ember/component";
import { LinkTo } from "@ember/routing";
import { tagName } from "@ember-decorators/component";

@tagName("")
export default class GarageTab extends Component {
  <template>
    <li class="user-main-nav-outlet garage" ...attributes>
      <LinkTo @route="user.garage">
        <span>🚗 Garage</span>
      </LinkTo>
    </li>
  </template>
}
