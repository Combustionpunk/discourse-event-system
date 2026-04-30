# Discourse Event System — Project Backlog
> Plugin: `discourse-event-system` (RC Bookings for Misfits Discourse)
> Repo: `https://github.com/Combustionpunk/discourse-event-system`
> Last updated: 2026-04-30

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

---

## Recently Completed (This Session)

### Event Management
- [x] Event creation form fixes — tracked properties, @action decorator, async event.target capture
- [x] Draft events visible to admins in events list with 📝 Draft badge
- [x] Publish and Delete buttons on events list for admins
- [x] Event type dropdown in manage event edit form
- [x] Booking schedule dropdowns (open/close days before) on manage event edit form
- [x] Booking closing date field removed from manage form (replaced by relative dropdowns)

### RC Meetings Category View
- [x] Custom topic list connector replacing standard Discourse topic list
- [x] Rich event cards with org logo, booking status badge, date, venue, class tags
- [x] Today/Upcoming/Past ordering (today first, then upcoming, then past)
- [x] Five filter dropdowns: time period, organisation, event type, environment, surface
- [x] Standard topic list, tabs and New Topic button hidden in RC Meetings

---

## Backlog (To Do)

### High Priority
- [ ] **Driver matching — transponder first, then BRCA, then name**
- [ ] **Badge double-award guard** — check if user already has badge before granting on re-publish
- [ ] **Membership creation restriction** — only organisation officials

### Medium Priority — RC Meetings Category
- [ ] **Further card improvements** — additional info on event cards (e.g. number of spaces remaining, entry fee)
- [ ] **Calendar view** — toggle between list and calendar view on RC Meetings category
- [ ] **Distance filtering** — filter events by distance from postcode
  - Add postcode field to My Racing Profile (auto-used for logged in users)
  - Manual postcode entry for non-logged in users
  - Use postcodes.io API for distance calculation

### Medium Priority — Events Management
- [ ] **Event "today" status** — closing bookings on the day triggers "event running" state in widget; show "⏳ Awaiting Results"
- [ ] **Widget — results state** — after results published and all drivers matched, show podium + who attended
- [ ] **Event page** — admin-facing only; remove booking UI from event page
- [ ] **"Alert me when booking opens"** — Discourse notification + email; needs `des_event_booking_alerts` table + background job

### Medium Priority — Results
- [ ] **Results correction UI** — edit positions, laps, times before publishing
- [ ] **Whole-meeting fastest lap** — scrape qualifying rounds too
- [ ] **Individual lap times** — scrape lap-by-lap data

### Medium Priority — Discovery
- [ ] **Category view as primary UX** — members browse events from RC Meetings; event list page for organisers only

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
- Transponder shortcode stored as integer, displayed with `#` prefix
- Plugin uses `des_` prefix for all models and custom fields
- Custom user fields: `brca_membership_number`, `des_date_of_birth`, `des_f_grade`, `des_t_grade`
- PayPal used for payment processing
- RC Results Venue ID 1075 = Sheffield Off Road & Rally RCC (SOAR)
- Championship round events = event type name contains "championship"
- Podium = A Final positions 1, 2, 3 per class
- Fastest lap = fastest non-zero, non-rejected best_lap across ALL finals for the class
- Badges: "{OrgName} Gold/Silver/Bronze/Fastest Lap"
- Discourse Docker deploy — no direct file access on live server, always rebuild
- Track surfaces: carpet, astroturf, grass, tarmac, mixed
- Booking schedule: relative to event date (days before), with manual override flags
- RC Meetings category name is hardcoded as "RC Meetings" in the plugin
