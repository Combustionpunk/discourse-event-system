import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class UserGarage extends Component {
  @tracked cars = null;
  @tracked isLoading = true;

  constructor() {
    super(...arguments);
    this.loadGarage();
  }

  async loadGarage() {
    try {
      const username = this.args.outletArgs?.model?.username;
      if (!username) return;
      const response = await ajax(`/des/garage/${username}/public.json`);
      this.cars = response.cars || [];
    } catch {
      this.cars = [];
    } finally {
      this.isLoading = false;
    }
  }

  <template>
    {{#if this.cars.length}}
      <div class="user-profile-garage">
        <h3>🚗 Garage</h3>
        <div class="profile-garage-grid">
          {{#each this.cars as |car|}}
            <div class="profile-garage-card">
              <div class="profile-garage-card-name">{{car.friendly_name}}</div>
              <div class="profile-garage-card-details">
                <span>{{car.manufacturer}} {{car.model}}</span>
                {{#if car.driveline}}
                  <span class="profile-garage-tag">{{car.driveline}}</span>
                {{/if}}
                {{#if car.chassis_type}}
                  <span class="profile-garage-tag">{{car.chassis_type}}</span>
                {{/if}}
              </div>
            </div>
          {{/each}}
        </div>
      </div>
    {{/if}}
  </template>
}
