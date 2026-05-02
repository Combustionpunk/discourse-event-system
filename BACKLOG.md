

Medium Priority — RC Meetings Category

 Spaces remaining on cards — show total spaces remaining across all classes
 Entry fee on cards — show "From £X" on event cards

Medium Priority — Events Management

 Event "today" status — closing bookings on the day triggers "event running" state in widget; show "⏳ Awaiting Results"
 Widget — results state — after results published and all drivers matched, show podium + who attended
 "Alert me when booking opens" — further improvements: resend options, admin view of who has alerts set

Medium Priority — Results

 Live timing integration — pull results directly from timing software (no manual entry)
 Results correction UI — edit positions, laps, times before publishing
 Improved results analysis — lap times, qualifying vs final comparisons, head-to-head stats
 Whole-meeting fastest lap — scrape qualifying rounds too
 Individual lap times — scrape lap-by-lap data

Medium Priority — Discovery

 Season standings — aggregate results across championship rounds, auto-calculated from published results

Low Priority

 RC Results live view — link to live race page during event
 Promote plugin to other clubs — separate forum post for club admins outlining admin benefits


Known Issues / Bugs

 Re-publishing results re-awards badges — needs guard before BadgeGranter.grant
 Driver auto-matching is name-only — produces incorrect matches occasionally
 Distance filtering excludes events with no venue/postcode — should include them with a "distance unknown" note


Conventions & Decisions

Junior age threshold: under 16 at event start date
Member Type Numbers: 1 = junior member, 2 = adult member, 3 = junior non-member, 4 = adult non-member
Transponder shortcode stored as integer, displayed with # prefix
Plugin uses des_ prefix for all models and custom fields
Custom user fields: brca_membership_number, des_date_of_birth, des_f_grade, des_t_grade, des_postcode
PayPal used for payment processing
RC Results Venue ID 1075 = Sheffield Off Road & Rally RCC (SOAR)
Championship round events = event type name contains "championship"
Podium = A Final positions 1, 2, 3 per class
Fastest lap = fastest non-zero, non-rejected best_lap across ALL finals for the class
Badges: "{OrgName} Gold/Silver/Bronze/Fastest Lap"
Discourse Docker deploy — no direct file access on live server, always rebuild
Track surfaces: carpet, astroturf, grass, tarmac, mixed
Track types: permanent (🏁), popup (🏗️)
Booking schedule: relative to event date (days before), with manual override flags
RC Meetings category name is hardcoded as "RC Meetings" in the plugin
Geocoding via postcodes.io (no API key required)
Background jobs: geocode venue (regular), check booking alerts (scheduled hourly), membership expiry (scheduled)
Booking alerts: deleted after sending so users are only notified once per event


Setup Sheet System — Detailed Plan

This is a significant feature. Full design documented here before build starts.

Overview
A digital setup sheet system allowing club members to record, share and browse car setups. Linked to our existing car models, venues and events for club-specific context that general sites like So Dialed cannot provide.
Key Differentiators vs So Dialed

Setups linked to our venues — "setups that worked at Niagara on carpet"
Setups linked to our events — "John's setup when he won Round 3"
Setups linked to results — see what setup produced what lap time/finish
Club community focus — not a general public database
No PDF uploads — proper structured digital forms

Data Structure
des_setup_sheets — core table

user_id — who created it
car_model_id — links to des_car_models (determines which template/fields to show)
des_user_car_id — optional, links to a specific car in the user's garage
venue_id — optional, links to des_venues (pre-fills track surface/environment)
event_id — optional, links to des_events
title — e.g. "Niagara Carpet Base Setup"
track_surface — carpet/astroturf/grass/tarmac/mixed (pre-filled from venue)
track_environment — indoor/outdoor
track_grip — low/medium/high
track_moisture — dry/damp/wet
track_condition — smooth/bumpy/grooved/dusty/hard_pack/loamy
track_temperature — string
air_temperature — string
qualify_position — integer
main_position — integer
best_lap_time — string
average_lap_time — string
is_public — boolean (share with club or keep private)
setup_data — JSONB (all model-specific fields)
timestamps

des_setup_sheet_templates — defines fields per car model

car_model_id
template_data — JSONB array of sections and fields

Template structure (JSONB):
json[
  {
    "section": "front_suspension",
    "label": "Front Suspension",
    "fields": [
      { "key": "ride_height", "label": "Ride Height", "type": "text", "unit": "mm" },
      { "key": "camber", "label": "Camber", "type": "text", "unit": "°" },
      { "key": "toe", "label": "Toe", "type": "text", "unit": "°" },
      { "key": "anti_roll_bar", "label": "Anti-Roll Bar", "type": "text" },
      { "key": "arm_type", "label": "Arm Type", "type": "text" },
      { "key": "caster_block", "label": "Caster Block", "type": "select", "options": ["-2°", "-1°", "0°", "+1°", "+2°"] }
    ]
  }
]
Field types: text, number, select, checkbox, textarea (for notes)
Sections (common across most models)

Track Conditions — surface, grip, moisture, condition, temperature (structured columns)
Front Suspension — ride height, camber, toe, anti-roll bar, arm type, tower type, wheel hex, caster block, axle height, ball stud spacing, steering plate
Rear Suspension — ride height, camber, anti-roll bar, arm type, tower type, wheel hex, hub type, drive shaft type, axle height, diff height
Shocks (Front & Rear) — piston, thickness, fluid, spring, stroke, eyelet, cup offset, limiters (int/ext)
Differentials — front/centre/rear fluid, gears, type, diff setting
Electronics — radio, servo, ESC, ESC settings, motor/wind, timing, pinion, spur, battery, EPA throttle/brake %, battery position
Drivetrain — slipper clutch type/pads/setting, drive ratio, driveshafts
Tires (Front & Rear) — brand, compound, insert, wheel
Body & Weight — body, front wing, rear wing, wing angle, chassis length, total weight, ballast
Notes — free text general notes, timestamped section notes

Features to Build (Phase 1)

 Create/edit setup sheet — dynamic form based on car model template
 View your own setups (My Setups tab on Racing Profile)
 Browse club setups — filterable by car model, venue, surface
 Clone a setup as a starting point
 Link setup to an event (optional)
 Public/private toggle
 Export to PDF — clean printable output similar to manufacturer sheets

Features to Build (Phase 2)

 Rating/comments from other club members
 "Race used" badge with result attached
 Setup comparison — view two setups side by side
 "What setup worked here" — browse by venue showing best results
 Admin — create/edit model templates in DES Admin

DB Tables Needed

des_setup_sheets — main setup records
des_setup_sheet_templates — field definitions per car model
des_setup_sheet_notes — timestamped notes per section (optional, could be in JSONB)

UI Location

My Racing Profile → new "My Setups" tab
Venue page → "Setups at this venue" section
Event page → "Setups used at this event" section (post-event)
Car model page → "Community setups for this model" section
Sidebar → possibly a "Setups" link under RC Racing

Build Order

Migration + models + template system
DES Admin — create/edit templates per car model
Setup sheet form (dynamic based on template)
My Setups tab on Racing Profile
Browse setups page
Export to PDF
Phase 2 features


Setup Sheet System — Confirmed Approach (Proof of Concept Complete)

Status: Planned — Large Feature
Proof of concept: PDF extraction tested on Team Associated B84, T7, B71, RC10 sheets
PDF extraction quality: Excellent — 155 fields auto-detected, 10 sections auto-grouped, 44 diagrams extracted
Mobile form prototype: Built and tested in session 2026-05-02

Confirmed Technical Approach
PDF Extraction (proven):

pypdf library extracts all form fields with names, types (text/checkbox) and groupings
Team Associated PDFs are exceptionally well structured — field names like "Front Ride Height", "Diff Front Fluid", "Arm Mount A Deg"
Auto-grouping into sections works well with minor cleanup needed
44 images extracted per PDF (technical diagrams) — stored as PNG uploads in Discourse
Admin cleanup pass in DES Admin required after extraction to fix any mis-grouped fields

Web Form (proven):

Dynamic form rendered from template definition (JSONB per car model)
Tab navigation per section — works well on mobile
Front/rear split panels for shocks and tires
Toggle switches for checkbox fields
Venue dropdown auto-populates track surface
Share toggle at bottom

Data Storage:

des_setup_sheet_templates — field definitions per car model (JSONB)
des_setup_sheets — user setup records with JSONB setup_data + structured columns for venue, event, result

Build Phases
Phase 1 — PDF extraction + admin template tools

 PDF upload field on car model record in DES Admin
 Backend PDF parser — extracts fields, groups into sections, extracts diagram images
 DES Admin template editor — review/reorder/rename fields, assign diagrams to sections, publish
 des_setup_sheet_templates table

Phase 2 — Setup sheet data model

 des_setup_sheets table:

user_id, car_model_id, des_user_car_id (optional)
venue_id → auto-populates track_surface, track_environment
event_id (optional)
title, is_public
qualify_position, main_position, best_lap_time
setup_data (JSONB)
parent_setup_id (for clones)
timestamps


 Model + associations

Phase 3 — Web form UI

 Dynamic form rendered from template
 Tab navigation per section
 Diagrams displayed alongside relevant sections
 Venue dropdown → auto-populates surface/environment
 Toggle switches for checkbox fields
 Save draft / Save final
 Mobile optimised for track-side use

Phase 4 — Garage integration

 My Setups tab on My Racing Profile
 New Setup from garage (select car → form loads correct template)
 Edit existing setup
 Clone own setup as new starting point

Phase 5 — Community & model page

 Setups tab on car model page — all public setups for that model
 Filter by venue, surface, result
 Clone button — copies setup to garage as starting point
 Shows submitter, venue, result achieved

Phase 6 — Export

 Export setup to PDF — clean printable format

Notes

Team Associated PDFs are ideal for this — very clean field names
Other manufacturers may need more admin cleanup
Diagrams are the most complex part — they need to be associated with the correct section manually during admin review
The "clone → race → share" workflow is the key differentiator vs So Dialed