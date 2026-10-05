# discourse-event-system

Core conventions in `../../CLAUDE.md` apply here too.

## Running Ruby

Ruby only exists inside the `discourse_dev` Docker container, so run Ruby tooling from the Discourse root (`../..`) through `d/exec`. Paths are relative to `/src`, the Discourse root inside the container.

```bash
# Specs (LOAD_PLUGINS=1 is required, or the plugin's routes and models are missing)
d/exec env LOAD_PLUGINS=1 RAILS_ENV=test bin/rspec plugins/discourse-event-system/spec
d/exec env LOAD_PLUGINS=1 RAILS_ENV=test bin/rspec plugins/discourse-event-system/spec/requests/car_model_permissions_spec.rb

# Rails runner (development database)
d/exec env LOAD_PLUGINS=1 bin/rails runner 'p DesCarModel.count'

# RuboCop and formatting on specific files
d/exec bundle exec rubocop plugins/discourse-event-system/path/to/file.rb
d/exec bundle exec stree write plugins/discourse-event-system/path/to/file.rb
```

`d/exec` passes `-it` to `docker exec`, so it fails without a terminal ("stdin is not a terminal"). From a non-interactive shell, wrap it in `script`:

```bash
script -qec "d/exec env LOAD_PLUGINS=1 RAILS_ENV=test bin/rspec plugins/discourse-event-system/spec" /dev/null
```

## Code notes

- `plugin.rb` uses `require_relative` for app files. `load` re-executes files Zeitwerk already loaded and causes "already initialized constant" warnings.
- Many older files predate `stree` formatting. Format new files, but avoid reformatting whole existing files in unrelated changes.
- Car model and manufacturer permissions go through `Guardian#can_edit_car_models?` (admin-only) and the `visible_to` scopes on `DesCarModel` and `DesManufacturer`. `spec/requests/car_model_permissions_spec.rb` covers them.
