import { i18n } from "discourse-i18n";
import { logoBackdrop } from "../lib/des-logo-backdrop";
import DesLogoUploader from "./des-logo-uploader";

const DesBoxArtPlaceholder = <template>
  <div
    class="des-box-art-placeholder
      {{if @large 'des-box-art-placeholder--large'}}"
  >
    <span aria-hidden="true" class="des-box-art-placeholder__logo">
      {{#if @logoUrl}}
        <img alt="" loading="lazy" src={{@logoUrl}} {{logoBackdrop}} />
      {{else}}
        🏭
      {{/if}}
    </span>

    {{#if @pending}}
      <span class="des-box-art-placeholder__action">
        {{i18n "discourse_event_system.car_models.box_art.pending_review"}}
      </span>
    {{else if @onSuggest}}
      <span class="des-box-art-placeholder__action">
        <DesLogoUploader
          @compact={{true}}
          @onUpload={{@onSuggest}}
          @uploadingLabel={{i18n
            "discourse_event_system.car_models.box_art.uploading"
          }}
          @uploadLabel={{i18n "discourse_event_system.car_models.box_art.add"}}
        />
      </span>
    {{/if}}
  </div>
</template>;

export default DesBoxArtPlaceholder;
