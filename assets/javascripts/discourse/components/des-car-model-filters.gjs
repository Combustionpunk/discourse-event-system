import { fn, hash } from "@ember/helper";
import DButton from "discourse/ui-kit/d-button";
import DFilterInput from "discourse/ui-kit/d-filter-input";
import { i18n } from "discourse-i18n";

const DesCarModelFilters = <template>
  <div class="des-model-filters">
    <DFilterInput
      class="des-model-filters__search"
      placeholder={{i18n
        "discourse_event_system.car_models.search_placeholder"
      }}
      @containerClass="des-model-filters__search-container"
      @filterAction={{@onSearchInput}}
      @icons={{hash left="magnifying-glass"}}
      @onClearInput={{@onClearSearch}}
      @value={{@searchValue}}
    />

    {{#each @groups as |group|}}
      {{#if group.options.length}}
        <div class="des-model-filters__group" data-filter-group={{group.key}}>
          <span class="des-model-filters__label">{{group.label}}</span>
          <div class="des-model-filters__chips">
            {{#each group.options as |option|}}
              <DButton
                aria-pressed={{if option.active "true" "false"}}
                class="btn-small des-model-filters__chip
                  {{if option.active 'des-model-filters__chip--active'}}"
                @action={{fn @onToggle group.key option.value}}
                @translatedLabel={{option.label}}
              />
            {{/each}}
          </div>
        </div>
      {{/if}}
    {{/each}}

    {{#if @hasActiveFilters}}
      <DButton
        class="btn-flat btn-small des-model-filters__clear"
        @action={{@onClear}}
        @icon="xmark"
        @label="discourse_event_system.car_models.filters.clear"
      />
    {{/if}}
  </div>
</template>;

export default DesCarModelFilters;
