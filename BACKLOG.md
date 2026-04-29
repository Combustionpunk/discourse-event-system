CopyDiscourse Event System — Project Backlog

Plugin: discourse-event-system (RC Bookings for Misfits Discourse)
Repo: https://github.com/Combustionpunk/discourse-event-system
Last updated: 2026-04-29


Working Method

Planning & discussion happens in Claude.ai chat (this Project)
Claude.ai produces prompts → pasted into Claude Code for file edits
Claude Code commits and pushes: cd /workspace/discourse/plugins/discourse-event-system && git push
Test locally first, then deploy live
Live deploy: SSH into live server → cd /var/discourse && ./launcher rebuild app
Plugin is pulled from GitHub during rebuild
At end of each session: update BACKLOG.md, commit and push
psql access on live: ./launcher enter app → su discourse -s /bin/bash -c "psql discourse"
Badge removal emergency SQL: DELETE FROM user_badges WHERE badge_id IN (SELECT id FROM badges WHERE name LIKE '%Sheffield Offroad%');
Copy plugin from container: docker exec -it 54edb91b770b bash -c "tar -czf /tmp/discourse-event-system.tar.gz -C /workspace/discourse/plugins discourse-event-system/" then docker cp 54edb91b770b:/tmp/discourse-event-system.tar.gz /mnt/c/Users/Yetidragon/Downloads/discourse-event-system.tar.gz


Recently Completed (This Session)
Car Models Public Page

 New /car-models page — public, grouped by manufacturer
 Manufacturer grid with logo support (upload via file picker)
 Clicking manufacturer scrolls to their models section
 Pending models show ⏳ Pending badge
 Admin: inline approve/reject/edit/delete on models and manufacturers
 Logged in users: "Add to My Garage" button per approved model
 Add to Garage opens reusable modal (DesAddCarModal) with manufacturer/model pre-selected
 Same modal used on My Garage page
 Car Models link in sidebar (visible to all)
 Model approval uses inline edit card (no more prompts)

Venue Improvements

 Reusable DesVenueForm component used on venues page and des-admin
 Admin venue creation button on venues page (no approval needed)
 Edit button on venue cards in des-admin
 Full facilities display on venue cards (emoji badges)
 Café facility added
 Track surface as dropdown (carpet, astroturf, grass, tarmac, mixed)

Event Management

 Booking schedule — "X days/weeks before event" dropdowns for open and close
 Manual open/close booking toggle on manage event page
 Widget checks booking_manually_closed and booking_open from server
 Event cloning — modal with title input and date picker
 Widget shows classes even when bookings not open
 Booking open date formatted readably in widget

Sidebar

 Removed redundant sidebar links (My Organisations, My Garage, My Bookings, My Memberships) — all accessible via My Racing Profile tabs


Backlog (To Do)
High Priority

 Driver matching — transponder first, then BRCA, then name
 Badge double-award guard — check if user already has badge for this event before granting on re-publish
 Membership creation restriction — only organisation officials

Medium Priority — Events Management

 Recurring/series events — create event across multiple dates at once (e.g. every Sunday in May)
 Event "today" status — closing bookings on the day triggers "event running" state in widget; currently events flip to "past" at midnight
 Category event ordering — show events in RC Meetings category chronologically by date
 "Alert me when booking opens" — Discourse notification + email when bookings open for an event (needs des_event_booking_alerts table + background job)

Medium Priority — Widget & Event Page Split

 Event page — admin-facing only; remove booking UI from event page, keep only admin items
 Widget — event running state — when admin closes booking on the day, show "⏳ Awaiting Results"
 Widget — results state — after results published and all drivers matched, show podium + who attended

Medium Priority — Discovery & Navigation

 Category view as primary UX — members browse events from RC Meetings category; event list page for organisers only
 Richer topic cards — org logo, event date, booking status, venue, venue features on category list
 Filters on RC events category — class, distance from user postcode, organisation
 Calendar view — toggle between list and calendar on category page; distance filter via postcodes.io API

Medium Priority — Results

 Results correction UI — edit positions, laps, times before publishing
 Whole-meeting fastest lap — scrape qualifying rounds too
 Individual lap times — scrape lap-by-lap data for second-fastest fallback

Low Priority

 RC Results live view — link to live race page during event
 Season standings — aggregate results across championship rounds


Known Issues / Bugs

 Re-publishing results re-awards badges — needs guard before BadgeGranter.grant
 Driver auto-matching is name-only — produces incorrect matches occasionally


Conventions & Decisions

Junior age threshold: under 16 at event start date
Member Type Numbers: 1 = junior member, 2 = adult member, 3 = junior non-member, 4 = adult non-member
No DOB set → defaults to senior (adult)
Transponder shortcode stored as integer, displayed with # prefix
Plugin uses des_ prefix for all models and custom fields
Custom user fields: brca_membership_number, des_date_of_birth, des_f_grade, des_t_grade
PayPal used for payment processing
RC Results Venue ID 1075 = Sheffield Off Road & Rally RCC (SOAR)
Championship round events = event type name contains "championship"
Podium = A Final positions 1, 2, 3 per class
Fastest lap = fastest non-zero, non-rejected best_lap across ALL finals for the class
Badges: "{OrgName} Gold/Silver/Bronze/Fastest Lap"
Discourse Docker deploy — no direct file access on live server, always rebuild
psql access on live: ./launcher enter app → su discourse -s /bin/bash -c "psql discourse"
Class type chassis_types/drivelines stored as comma-separated strings
Year range: 1970–current; Age options: 10, 14, 16, 18, 30, 40, 45
Scales: configurable in des-admin (des_scales table)
Chassis types: configurable in des-admin (des_chassis_types table)
Track surfaces: carpet, astroturf, grass, tarmac, mixed
Booking schedule: relative to event date (days before), with manual override flags