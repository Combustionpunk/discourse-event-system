# Discourse Event System — Project Backlog
> Plugin: `discourse-event-system` (RC Bookings for Misfits Discourse)
> Repo: `https://github.com/Combustionpunk/discourse-event-system`
> Last updated: 2026-05-01

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

## Recently Completed

### Event Management
- [x] Event creation form fixes — tracked properties, @action decorator, async event.target capture
- [x] Draft events visible to admins in events list with 📝 Draft badge
- [x] Publish and Delete buttons on events list for admins
- [x] Event type dropdown in manage event edit form
- [x] Booking schedule dropdowns (open/close days before) on manage event edit form
- [x] Booking UI removed from /events/:id page — read-only class list and booking status only
- [x] Events sidebar link restricted to admins only
- [x] Upcoming Events sidebar link removed for regular users

### RC Meetings Category View
- [x] Custom topic list connector replacing standard Discourse topic list
- [x] 3-section event cards — header (title/date/badges), body (org | venue+facilities), footer (classes + booking status)
- [x] Facility icons with CSS hover tooltips
- [x] Today/Upcoming/Past ordering (today first, then upcoming, then past)
- [x] Filter dropdowns: time period, organisation, event type, environment, surface
- [x] Distance filter with postcodes.io — pre-fills from racing profile postcode, manual entry for others
- [x] Calendar view with month grid, multi-event popover, colour-coded by booking status
- [x] Standard topic list, tabs and New Topic button hidden in RC Meetings
- [x] 🔔 Booking alert button on RC Meetings cards (Booking Soon events only)

### Venues
- [x] Postcode field on venues
- [x] Latitude/longitude columns with auto-geocoding via background job (postcodes.io)
- [x] "Fetch Missing Coordinates" button in DES Admin venues tab
- [x] Map view on /venues page using Leaflet.js + OpenStreetMap
- [x] Track type field (🏁 Permanent / 🏗️ Pop-up) on venues
- [x] Icon key modal on venues page explaining all facility/surface/environment icons

### Booking Alerts
- [x] des_event_booking_alerts table and model
- [x] Subscribe/unsubscribe API endpoints
- [x] Hourly background job — checks for events where booking just opened, notifies subscribed users
- [x] Email notification with event details and link to topic thread
- [x] Discourse bell notification on booking open
- [x] 🔔 Alert Me button on booking widget (shown when booking not yet open)

### User Profile
- [x] Postcode field on My Racing Profile (des_postcode custom user field)
- [x] Used for distance filtering in RC Meetings

### Communications
- [x] Forum post — Introducing the RC Racing System
- [x] Forum post — How to Use the RC Racing System
- [x] Full video walkthrough voiceover script
- [x] Social media highlight reel script (60-90 seconds)
- [x] Promotional flyer
- [x] All compiled into downloadable Word document

---

## Backlog (To Do)

### High Priority
- [ ] **Driver matching — transponder first, then BRCA, then name**
- [ ] **Badge double-award guard** — check if user already has badge before granting on re-publish
- [ ] **Membership creation restriction** — only organisation officials

### Medium Priority — Booking Alerts
- [ ] **Edit alert email templates via UI** — DES Admin setting to customise booking alert email subject and body

### Medium Priority — RC Meetings Category
- [ ] **Spaces remaining on cards** — show total spaces remaining across all classes
- [ ] **Entry fee on cards** — show "From £X" on event cards

### Medium Priority — Events Management
- [ ] **Event "today" status** — closing bookings on the day triggers "event running" state in widget; show "⏳ Awaiting Results"
- [ ] **Widget — results state** — after results published and all drivers matched, show podium + who attended
- [ ] **"Alert me when booking opens"** — further improvements: resend options, admin view of who has alerts set

### Medium Priority — Results
- [ ] **Live timing integration** — pull results directly from timing software (no manual entry)
- [ ] **Results correction UI** — edit positions, laps, times before publishing
- [ ] **Improved results analysis** — lap times, qualifying vs final comparisons, head-to-head stats
- [ ] **Whole-meeting fastest lap** — scrape qualifying rounds too
- [ ] **Individual lap times** — scrape lap-by-lap data

### Medium Priority — Discovery
- [ ] **Season standings** — aggregate results across championship rounds, auto-calculated from published results

### Low Priority
- [ ] **RC Results live view** — link to live race page during event
- [ ] **Promote plugin to other clubs** — separate forum post for club admins outlining admin benefits

---

## Known Issues / Bugs
- [ ] Re-publishing results re-awards badges — needs guard before BadgeGranter.grant
- [ ] Driver auto-matching is name-only — produces incorrect matches occasionally
- [ ] Distance filtering excludes events with no venue/postcode — should include them with a "distance unknown" note

---

## Conventions & Decisions
- Junior age threshold: **under 16** at event start date
- Member Type Numbers: `1` = junior member, `2` = adult member, `3` = junior non-member, `4` = adult non-member
- Transponder shortcode stored as integer, displayed with `#` prefix
- Plugin uses `des_` prefix for all models and custom fields
- Custom user fields: `brca_membership_number`, `des_date_of_birth`, `des_f_grade`, `des_t_grade`, `des_postcode`
- PayPal used for payment processing
- RC Results Venue ID 1075 = Sheffield Off Road & Rally RCC (SOAR)
- Championship round events = event type name contains "championship"
- Podium = A Final positions 1, 2, 3 per class
- Fastest lap = fastest non-zero, non-rejected best_lap across ALL finals for the class
- Badges: "{OrgName} Gold/Silver/Bronze/Fastest Lap"
- Discourse Docker deploy — no direct file access on live server, always rebuild
- Track surfaces: carpet, astroturf, grass, tarmac, mixed
- Track types: permanent (🏁), popup (🏗️)
- Booking schedule: relative to event date (days before), with manual override flags
- RC Meetings category name is hardcoded as "RC Meetings" in the plugin
- Geocoding via postcodes.io (no API key required)
- Background jobs: geocode venue (regular), check booking alerts (scheduled hourly), membership expiry (scheduled)
- Booking alerts: deleted after sending so users are only notified once per event