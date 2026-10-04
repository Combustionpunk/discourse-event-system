import { LinkTo } from "@ember/routing";

export default <template>
  <li class="user-main-nav-outlet garage">
    <LinkTo @route="user.garage">
      <span>🚗 Garage</span>
    </LinkTo>
  </li>
</template>
