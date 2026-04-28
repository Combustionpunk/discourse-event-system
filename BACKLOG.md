# Discourse Event System — Project Backlog
> Plugin: `discourse-event-system` (RC Bookings for Misfits Discourse)
> Repo: `https://github.com/Combustionpunk/discourse-event-system`
> Last updated: 2026-04-28

---

## Working Method
- Planning & discussion happens in Claude.ai chat (this Project)
- Claude.ai produces prompts → pasted into Claude Code for file edits
- Claude Code commits and pushes: `cd /workspace/discourse/plugins/discourse-event-system && git push`
- Test locally first, then deploy live
- Live deploy: SSH into live server → `cd /var/discourse && ./launcher rebuild app`
- Plugin is pulled from GitHub during rebuild
- At end of each session: update BACKLOG.md, commit and push
- psql access on live: `./launcher enter app` → `su discourse -s /bin/bash -c "psql discourse"`
- Badge removal emergency SQL: `DELETE FROM user_badges WHERE badge_id IN (SELECT id FROM badges WHERE name LIKE '%Sheffield Offroad%');`
- Copy plugin from container: `docker exec -it 54edb91b770b bash -c "tar -czf /tmp/discourse-event-system.tar.gz -C /workspace/discourse/plugins discourse-event-system/"` then `docker cp 54edb91b770b:/tmp/discourse-event-system.tar.gz /mnt/c/Users/Yetidragon/Downloads/discourse-event-system.tar.gz`

---

## Recently Completed (This Session)

### Garage / Car Model Refactoring
- [x] Split `chassis_type` into separate `scale` + `chassis_type` columns on `des_car_models`
- [x] Migration auto-splits existing records (e.g. "1/10 Buggy" → scale:"1/10", chassis_type:"Buggy")
- [x] Configurable scales and chassis types stored in DB (`des_scales`, `des_chassis_types`)
- [x] Des-admin: 📏 Scales and 🚗 Chassis Types tabs with add/delete UI
- [x] Dropdowns in des-admin and my-garage load dynamically from API

### Class Type System Overhaul
- [x] Unified class type form with all eligibility rules in one place
- [x] Class types have: track_environment, scale, chassis_types, drivelines, min/max year, manufacturer, model, min/max age
- [x] Reusable `DesClassTypeForm` component used in both des-admin and organisation pages
- [x] Global and org class types separated in des-admin rules tab with collapsible org groups
- [x] Edit and delete on both global and org class types
- [x] Car eligibility checks updated to use new class type attributes

### Transponder Registry
- [x] `des_user_transponders` table — shortcode (integer), long_code, notes per user
- [x] Existing car transponders imported automatically on migration
- [x] Racing profile: 📡 My Transponders section with add/edit/delete
- [x] Garage car transponder field replaced with registry dropdown
- [x] New codes prompt to save to registry
- [x] Car cards show `#1 — 1234567` format
- [x] Booking flow transponder confirmation step in widget
- [x] Changed transponders saved back to car record

---

## Backlog (To Do)

### High Priority
- [ ] **Driver matching — transponder first, then BRCA, then name** — match: 1) car_number vs booking transponder_number for the event, 2) BRCA number, 3) name
- [ ] **Badge double-award guard** — check if user already has badge for this event before granting on re-publish
- [ ] **Membership creation restriction** — only organisation officials should be able to create memberships

### Medium Priority — Events Management
- [ ] **Model approval tidy up** — replace prompt-based approve flow with edit card pattern (same as manufacturers)
- [ ] **Manual open/close booking** — button on event to manually open or close bookings, independent of automatic closing date
- [ ] **Auto-open booking on date** — set a future date in event config for when bookings automatically open (currently open immediately on creation)
- [ ] **Event cloning** — duplicate a previous event with new dates
- [ ] **Recurring/series events** — create event across multiple dates at once
- [ ] **Event "today" status** — currently events flip to "past" at midnight; add "today" status or change threshold. Consider admin option to manually mark event as running
- [ ] **Category event ordering** — option to display events in the RC Meetings category chronologically by date

### Medium Priority — Widget & Event Page Split
- [ ] **Event page** — should be admin-facing only; remove booking UI from event page, keep only admin items (manage event, results, entrants, etc.)
- [ ] **Widget — booking state** (before event, booking open): current booking UI as-is
- [ ] **Widget — event running state** (triggered when admin closes booking on the day): show "⏳ Awaiting Results" message; may still handle on-the-day admin bookings
- [ ] **Widget — results state** (after results published and all drivers matched): show podium cards + finishing positions for who attended

### Medium Priority — Discovery & Navigation
- [ ] **Category view as primary user experience** — members browse and interact with events from the RC Meetings category topic list; event list page for organisers only
- [ ] **Richer topic cards** — show org logo, event date, booking status, venue, venue features on category topic list
- [ ] **Filters on RC events category** — filter by class, distance from user, organisation
- [ ] **Calendar view** — toggle between list and calendar view on category page; distance filter uses postcode from racing profile via postcodes.io API

### Medium Priority — Results
- [ ] **Results correction UI** — edit positions, laps, times before publishing
- [ ] **Whole-meeting fastest lap** — scrape qualifying rounds too
- [ ] **Individual lap times** — scrape lap-by-lap data for second-fastest fallback

### Low Priority
- [ ] **RC Results live view** — link to live race page during event
- [ ] **Season standings** — aggregate results across championship rounds

---

## Known Issues / Bugs
- [ ] Re-publishing results re-awards badges — needs guard before BadgeGranter.grant
- [ ] Driver auto-matching is name-only — produces incorrect matches occasionally

---

## Conventions & Decisions
- Junior age threshold: **under 16** at event start date
- Member Type Numbers: `1` = junior member, `2` = adult member, `3` = junior non-member, `4` = adult non-member
- No DOB set → defaults to senior (adult)
- F Grade / T Grade range: `0–5`
- BRCA number defaults to `0` if not set in CSV export
- Transponder shortcode stored as integer, displayed with `#` prefix (e.g. `#1`)
- Transponder long code = hardware ID for RCTiming CSV export
- Plugin uses `des_` prefix for all models and custom fields
- Custom user fields: `brca_membership_number`, `des_date_of_birth`, `des_f_grade`, `des_t_grade`
- PayPal used for payment processing
- RC Results Venue ID 1075 = Sheffield Off Road & Rally RCC (SOAR)
- Championship round events = events with event type name containing "championship"
- Podium = A Final positions 1, 2, 3 per class
- Fastest lap = fastest non-zero, non-rejected best_lap across ALL finals for the class
- Badges per-organisation: "{OrgName} Gold/Silver/Bronze/Fastest Lap"
- Discourse Docker deploy — no direct file access on live server, always rebuild
- psql access on live: `./launcher enter app` → `su discourse -s /bin/bash -c "psql discourse"`
- Class type chassis_types/drivelines stored as comma-separated strings; helper methods `chassis_types_list`, `drivelines_list`
- Year range: 1970–current year; Age options: 10, 14, 16, 18, 30, 40, 45
- Scales: 1/8, 1/10, 1/12, 1/28 (configurable in des-admin)
- Chassis types: Buggy, Truck, Stadium, Short Course, Touring Car, Rally, Pan Car, Drift (configurable in des-admin)