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
- [ ] **Approach BRCA formally** — pitch platform to BRCA, request API/data access for member verification. Member check tool exists at brca.org/clubs/club-tools/member-check but is behind club login. Goal: (1) API or data sharing for membership verification, (2) BRCA recommending/endorsing platform to affiliated clubs. See business strategy notes.

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

---

## Setup Sheet System — Detailed Plan

> This is a significant feature. Full design documented here before build starts.

### Overview
A digital setup sheet system allowing club members to record, share and browse car setups. Linked to our existing car models, venues and events for club-specific context that general sites like So Dialed cannot provide.

### Key Differentiators vs So Dialed
- Setups linked to our venues — "setups that worked at Niagara on carpet"
- Setups linked to our events — "John's setup when he won Round 3"
- Setups linked to results — see what setup produced what lap time/finish
- Club community focus — not a general public database
- No PDF uploads — proper structured digital forms

### Data Structure

**`des_setup_sheets`** — core table
- `user_id` — who created it
- `car_model_id` — links to des_car_models (determines which template/fields to show)
- `des_user_car_id` — optional, links to a specific car in the user's garage
- `venue_id` — optional, links to des_venues (pre-fills track surface/environment)
- `event_id` — optional, links to des_events
- `title` — e.g. "Niagara Carpet Base Setup"
- `track_surface` — carpet/astroturf/grass/tarmac/mixed (pre-filled from venue)
- `track_environment` — indoor/outdoor
- `track_grip` — low/medium/high
- `track_moisture` — dry/damp/wet
- `track_condition` — smooth/bumpy/grooved/dusty/hard_pack/loamy
- `track_temperature` — string
- `air_temperature` — string
- `qualify_position` — integer
- `main_position` — integer  
- `best_lap_time` — string
- `average_lap_time` — string
- `is_public` — boolean (share with club or keep private)
- `setup_data` — JSONB (all model-specific fields)
- `timestamps`

**`des_setup_sheet_templates`** — defines fields per car model
- `car_model_id`
- `template_data` — JSONB array of sections and fields

**Template structure (JSONB):**
```json
[
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
```

**Field types:** text, number, select, checkbox, textarea (for notes)

### Sections (common across most models)
1. **Track Conditions** — surface, grip, moisture, condition, temperature (structured columns)
2. **Front Suspension** — ride height, camber, toe, anti-roll bar, arm type, tower type, wheel hex, caster block, axle height, ball stud spacing, steering plate
3. **Rear Suspension** — ride height, camber, anti-roll bar, arm type, tower type, wheel hex, hub type, drive shaft type, axle height, diff height
4. **Shocks (Front & Rear)** — piston, thickness, fluid, spring, stroke, eyelet, cup offset, limiters (int/ext)
5. **Differentials** — front/centre/rear fluid, gears, type, diff setting
6. **Electronics** — radio, servo, ESC, ESC settings, motor/wind, timing, pinion, spur, battery, EPA throttle/brake %, battery position
7. **Drivetrain** — slipper clutch type/pads/setting, drive ratio, driveshafts
8. **Tires (Front & Rear)** — brand, compound, insert, wheel
9. **Body & Weight** — body, front wing, rear wing, wing angle, chassis length, total weight, ballast
10. **Notes** — free text general notes, timestamped section notes

### Features to Build (Phase 1)
- [ ] Create/edit setup sheet — dynamic form based on car model template
- [ ] View your own setups (My Setups tab on Racing Profile)
- [ ] Browse club setups — filterable by car model, venue, surface
- [ ] Clone a setup as a starting point
- [ ] Link setup to an event (optional)
- [ ] Public/private toggle
- [ ] Export to PDF — clean printable output similar to manufacturer sheets

### Features to Build (Phase 2)
- [ ] Rating/comments from other club members
- [ ] "Race used" badge with result attached
- [ ] Setup comparison — view two setups side by side
- [ ] "What setup worked here" — browse by venue showing best results
- [ ] Admin — create/edit model templates in DES Admin

### DB Tables Needed
1. `des_setup_sheets` — main setup records
2. `des_setup_sheet_templates` — field definitions per car model
3. `des_setup_sheet_notes` — timestamped notes per section (optional, could be in JSONB)

### UI Location
- **My Racing Profile** → new "My Setups" tab
- **Venue page** → "Setups at this venue" section
- **Event page** → "Setups used at this event" section (post-event)
- **Car model page** → "Community setups for this model" section
- **Sidebar** → possibly a "Setups" link under RC Racing

### Build Order
1. Migration + models + template system
2. DES Admin — create/edit templates per car model
3. Setup sheet form (dynamic based on template)
4. My Setups tab on Racing Profile
5. Browse setups page
6. Export to PDF
7. Phase 2 features


---

## Setup Sheet System — Confirmed Approach (Proof of Concept Complete)

> Status: Planned — Large Feature
> Proof of concept: PDF extraction tested on Team Associated B84, T7, B71, RC10 sheets
> PDF extraction quality: Excellent — 155 fields auto-detected, 10 sections auto-grouped, 44 diagrams extracted
> Mobile form prototype: Built and tested in session 2026-05-02

### Confirmed Technical Approach

**PDF Extraction (proven):**
- pypdf library extracts all form fields with names, types (text/checkbox) and groupings
- Team Associated PDFs are exceptionally well structured — field names like "Front Ride Height", "Diff Front Fluid", "Arm Mount A Deg"
- Auto-grouping into sections works well with minor cleanup needed
- 44 images extracted per PDF (technical diagrams) — stored as PNG uploads in Discourse
- Admin cleanup pass in DES Admin required after extraction to fix any mis-grouped fields

**Web Form (proven):**
- Dynamic form rendered from template definition (JSONB per car model)
- Tab navigation per section — works well on mobile
- Front/rear split panels for shocks and tires
- Toggle switches for checkbox fields
- Venue dropdown auto-populates track surface
- Share toggle at bottom

**Data Storage:**
- `des_setup_sheet_templates` — field definitions per car model (JSONB)
- `des_setup_sheets` — user setup records with JSONB setup_data + structured columns for venue, event, result

### Build Phases

**Phase 1 — PDF extraction + admin template tools**
- [ ] PDF upload field on car model record in DES Admin
- [ ] Backend PDF parser — extracts fields, groups into sections, extracts diagram images
- [ ] DES Admin template editor — review/reorder/rename fields, assign diagrams to sections, publish
- [ ] `des_setup_sheet_templates` table

**Phase 2 — Setup sheet data model**
- [ ] `des_setup_sheets` table:
  - user_id, car_model_id, des_user_car_id (optional)
  - venue_id → auto-populates track_surface, track_environment
  - event_id (optional)
  - title, is_public
  - qualify_position, main_position, best_lap_time
  - setup_data (JSONB)
  - parent_setup_id (for clones)
  - timestamps
- [ ] Model + associations

**Phase 3 — Web form UI**
- [ ] Dynamic form rendered from template
- [ ] Tab navigation per section
- [ ] Diagrams displayed alongside relevant sections
- [ ] Venue dropdown → auto-populates surface/environment
- [ ] Toggle switches for checkbox fields
- [ ] Save draft / Save final
- [ ] Mobile optimised for track-side use

**Phase 4 — Garage integration**
- [ ] My Setups tab on My Racing Profile
- [ ] New Setup from garage (select car → form loads correct template)
- [ ] Edit existing setup
- [ ] Clone own setup as new starting point

**Phase 5 — Community & model page**
- [ ] Setups tab on car model page — all public setups for that model
- [ ] Filter by venue, surface, result
- [ ] Clone button — copies setup to garage as starting point
- [ ] Shows submitter, venue, result achieved

**Phase 6 — Export**
- [ ] Export setup to PDF — clean printable format

### Notes
- Team Associated PDFs are ideal for this — very clean field names
- Other manufacturers may need more admin cleanup
- Diagrams are the most complex part — they need to be associated with the correct section manually during admin review
- The "clone → race → share" workflow is the key differentiator vs So Dialed


---

## Business Strategy & Growth — Session 2026-05-02

> Full strategy discussion completed this session. Key decisions and actions documented below.

---

### Revenue Model — Confirmed Structure

**Tier 1 — Free Forever**
- Unlimited event listings — no cap, no friction
- Link to own booking method — no payment processing required
- Basic club profile page on RC Misfits
- Events scraped from BRCA calendar and RC-Results listed automatically (clubs may not even know yet)
- Goal: become the definitive UK RC event directory, build habit, drive traffic
- Conversion path: clubs notice their events getting engagement → natural upgrade conversation

**Tier 2 — Full Bookings**
- 5% surcharge per booking (pay as you go)
- OR £25/month flat fee (better for clubs running 1+ events/month)
- Break-even vs flat fee: £500/month in bookings = ~1 event/month at 30 drivers × £15
- Includes: full booking flow, automated PayPal payouts, member management, results publishing
- Cheaper than Eventbrite (6.95% + 59p/ticket) and massively better product

**Tier 3 — Full Platform (future — when timing integration built)**
- 10% surcharge per booking
- OR £75/month flat fee
- Includes everything in Tier 2 plus: timing integration, RC-Results replacement, BRCA verification, setup sheet library, priority support
- Replaces: RC-Timing (£207.50/yr) + RC-Results (£37.50/yr) + Eventbrite fees
- Net saving to club even at 10% vs current costs

**Competitive position:**
- Current club costs: RC-Timing £415/2yr + RC-Results £75/2yr = £245/year + Eventbrite 6.95%
- RC Misfits Tier 2 at 5% is cheaper than Eventbrite alone
- RC Misfits Tier 3 at 10% replaces all software costs and is still net positive for most clubs

---

### Revenue Projections

| Year | Tier 2 Clubs | Tier 3 Clubs | Forum Members | Total |
|------|-------------|-------------|--------------|-------|
| 2026 | 5 × £225 avg | 1 × £900 | 50 × £72/yr | ~£6,225 |
| 2027 | 15 × £225 avg | 5 × £900 | 150 × £72/yr | ~£20,475 |
| 2028 | 30 × £225 avg | 15 × £900 | 400 × £72/yr | ~£53,850 |

Note: 300+ BRCA affiliated clubs in UK. 15% Tier 3 penetration = 45 clubs = £40,500/year from Tier 3 alone.

---

### Forum Membership — RC PitGrid Anchor

**Product name confirmed: RC PitGrid**
- Register rcpitgrid.com
- Create @rcpitgrid Instagram
- Release on Printables as "RC PitGrid by RC Misfits" (2-3 free teaser files, full library behind membership)

**The system:**
- Modular pit organisation system designed specifically for RC racing
- Custom 12mm grid (tighter than standard 42mm Gridfinity — better for small RC components)
- Uses Gridfinity generation website for grids and box bottoms
- Designed in Shapr3D (investigating FreeCAD/Ondsel)
- Printed on Bambu Labs P1S — prototyping in PLA, release files in PETG (heat resistance for car boots)
- Current files: motor storage, ESC, oil bottles, servos, springs, soldering iron, diff holders — all tested
- Missing: Euro crate conversion system (in progress) — 3D printed parts to convert standard Euro crate into pit box
- Currently fits TSTAK/off-the-shelf boxes

**Euro crate conversion — why it matters:**
- Euro crates £5-15 vs £30-40 for TSTAK system
- Lower barrier to entry = more people building = more social proof = more conversions
- Side rail clips, corner locks, inner tray system, optional lid/top tray
- "Starter" (Euro crate) and "Pro" (TSTAK/Packout) use same 12mm modules — modules transfer on upgrade

**Membership pricing — single tier to start:**
- £6/month or £60/year (2 months free)
- Includes: all RC PitGrid files, early YouTube access, members forum section, new files monthly
- Add tiers later once established

**Membership launch plan:**
1. Finish Euro crate conversion files
2. Switch all files to PETG recommendations
3. Film SOAR event (8 days) — pit box in use at real race meeting
4. Publish YouTube launch video: "I built a modular RC pit box system for under £20 — files free for RC Misfits members"
5. Post on Printables with 2-3 free teaser files linking to RC Misfits
6. Go live with membership tier on forum

**Membership revenue potential:**
- 100 members = £600/month = £7,200/year
- 300 members (realistic after good YouTube performance) = £1,800/month = £21,600/year

**Important decision: setup sheets stay FREE**
- Community-generated content must not be paywalled — kills adoption and goodwill
- Setup sheet system drives forum engagement and accounts, not direct revenue
- Paywall principle: platform-created content (RC PitGrid files, YouTube early access, written guides) = paid. Community content (setup sheets, forum posts, results) = always free.

---

### YouTube Strategy

**Current state:** 740 subscribers, sporadic uploads, mix of build videos and events

**The bottleneck:** Editing time — not equipment, not ideas

**Solutions:**
- CapCut or Descript for faster editing (edit video by editing transcript)
- Batch filming — 3-4 videos in one session
- Templates — same intro/outro/lower thirds every time, editing becomes assembly
- Shorts from long-form — film once, get multiple pieces of content

**Two target audiences — both need serving:**
1. Individual racers → forum membership funnel
2. Club admins → platform acquisition funnel

**Priority videos:**
- "How we run race day for 40 drivers" — film at SOAR in 8 days. Unique content nobody else makes. Gets shared in club WhatsApp groups and committee meetings.
- RC PitGrid launch video — "I built a modular RC pit box system, files free for RC Misfits members"
- Tuning how-to content — "why your buggy pushes and how to fix it" — high search volume, feeds setup sheet system
- "How we replaced Eventbrite for our RC club and saved £300 a year" — directly targets club admin audience

**YouTube → platform connection (every video):**
- Description links to RC Misfits forum and event finder
- Build videos mention setup sheet system
- Event videos show booking system in action
- One video per quarter specifically for club admins

---

### Club Acquisition Strategy

**The advantage:** You're one of them. You race, you run events (you run SOAR), you understand the pain from the inside. This is your biggest differentiator vs any external platform.

**The SOAR story:**
- You built the platform because nothing else did what you needed
- You are the case study — club admin AND platform builder
- "I run SOAR and I built this" is more credible than any sales pitch

**Acquisition funnel:**

**Awareness channels:**
- Word of mouth from racers — SOAR drivers race at other clubs, they'll talk
- Event directory — scraping BRCA calendar brings organic search traffic
- YouTube — club admin video gets found by people searching "how to run RC race meetings"
- RC Facebook groups — genuine engagement, not spam
- BRCA regional section committees — one conversation = 30-40 clubs

**Interest — what needs to exist:**
- [ ] `/for-clubs` landing page — speaks directly to club admins, clear tier pricing, screenshots, SOAR case study
- SOAR case study: real numbers, before/after, quote from club admin (you)
- "Before: Facebook events, bank transfers, spreadsheets, 3 hours admin. After: 20 minutes."

**Trial — lowering the barrier:**
- Free event listing — zero commitment
- White glove onboarding for first 10 clubs — personally set up their org and first event
- "Try it alongside your current system" — no obligation
- Money-back on first event surcharge if anything goes wrong

**Commitment — what makes clubs stay:**
- Payout reliability — first payout must arrive on time, correct to the penny
- Data lock-in (the good kind) — member database, booking history, results history all live on RC Misfits
- Results on Google — if their results are being found through RC Misfits, visible value
- Member adoption — once 80% of members have accounts, club effectively can't leave

**Expansion:**
- Tier 2 → Tier 3 when timing integration live
- Multiple organisations per club (off-road + on-road series)
- Championship management → season standings → Tier 3 natural upgrade

**Outreach approach:**
- Warm outreach through racing connections — WhatsApp from racer to racer, not cold email
- Target regional series coordinators — one conversation = 8-10 clubs
- Template: "Hi [Name], SOAR just ran their first event through RC Misfits and it went really well. Would you be open to a 15 minute call? Happy to set up your first event for free."

**First 10 clubs — where they come from:**
1. SOAR ✅ already on platform
2. Clubs SOAR members also race at — 3-4 warm leads already in network
3. East Midlands regional series clubs
4. Inbound from YouTube video
5. BRCA connection referrals

---

### Infrastructure — Completed This Session

- [x] Droplet upgraded: 1vCPU/2GB → 2vCPU/4GB RAM (~£21-22/month with backups)
- [x] Snapshot taken pre-resize: `pre-resize-may-2026`
- [x] UptimeRobot monitoring configured — 5 minute intervals, email + SMS alerts
- [x] Sidekiq dead jobs cleared — 8,641 old dev artifacts removed
- [x] Discourse confirmed up to date: 2026.5.0-latest
- [x] All health checks passed post-resize

---

### Costs — Current and Scaling

**Current monthly costs:**
| Item | Monthly | Annual |
|------|---------|--------|
| Digital Ocean (post-resize) | £21-22 | ~£260 |
| Mailgun | £12 | £144 |
| Domain | £0.83 | £10 |
| **Total** | **~£35** | **~£414** |

Break-even: 6 forum members at £6/month covers all costs.

**Scaling costs:**
| Stage | Clubs | Users | Monthly Cost |
|-------|-------|-------|-------------|
| Current | 1-2 | ~100 | £35 |
| Stage 2 | 5-10 | ~500 | ~£70 |
| Stage 3 | 20-30 | ~2,000 | ~£155 |
| Stage 4 | 50+ | ~5,000 | £300-400 |

At Stage 4, revenue should be £5,000-10,000/month so infrastructure is <5% of revenue.

**Email at scale:** Consider migrating from Mailgun to Amazon SES — £0.10/1,000 emails vs Mailgun pricing. At 90,000 emails/month = £9/month on SES vs £60-80 on Mailgun.

---

### Risks — Summary and Mitigations

**Technical risks:**
- Single server point of failure — mitigated by backups, UptimeRobot, snapshot ✅
- 8,641 dead Sidekiq jobs — cleared this session ✅
- Security — ensure DO firewall configured, 2FA on DO and GitHub accounts
- [ ] Test backup restore — has never been tested, do this soon

**Financial risks:**
- Cash flow — forum membership covers costs within 6 forum members
- PayPal freeze risk — keep account verified, move money to bank regularly, add Stripe as backup (future)
- Pricing pressure — timing integration is the key retention mechanism, makes switching cost enormous

**Competitive risks:**
- RC-Timing could add booking features — consider partnership approach rather than waiting for competition
- Community moat (forum, YouTube, RC PitGrid, results history) can't be replicated quickly
- BRCA partnership/endorsement would be significant competitive barrier

**Dependency risks:**
- RC-Timing integration needed for Tier 3 — design as provider-agnostic from start
- BRCA — approach as partner not adversary
- Hetzner as DO alternative at Stage 3 — ~40% cheaper for same specs

**Personal risks:**
- Burnout — 120 hours in 4 weeks is not sustainable long term
- Forum membership revenue removes cost pressure, changes psychological dynamic
- Batch work sessions, consider part-time editor for YouTube (£15-20/hour) when revenue allows
- Single developer — documentation (this backlog) helps future handover
- Scope creep — maximum 2-3 active features at once, revenue-generating features get priority

**Legal/compliance risks:**
- [ ] GDPR privacy policy — needed before first paying club (within 30 days)
- [ ] ICO registration — £40/year, required when processing personal data commercially
- [ ] Terms and conditions — before first paying club (£200-300 solicitor)
- Children's Code applies — parental consent needed for under-16 registrations
- PayPal/Stripe handles card data — never handle raw card data directly ✅
- VAT threshold £90,000 — unlikely near term but know it exists
- [ ] Talk to accountant when monthly revenue exceeds £500

**Urgent actions from risk review:**
- ✅ Server upgraded
- ✅ UptimeRobot live
- ⏳ Test backup restore (this month)
- ⏳ ICO registration + privacy policy (within 30 days)
- ⏳ Terms and conditions (before first paying club)

---

### BRCA Partnership Strategy

**What exists:**
- Member check tool at brca.org/clubs/club-tools/member-check — behind club login
- No public API — Joomla-based CMS
- BRCA membership: Adult £30/yr, Junior £15/yr, Non-driving £20/yr, renews calendar year

**Your position:**
- BRCA affiliated club chairman (SOAR)
- Built a platform that benefits their entire affiliated club network
- Peer-to-peer conversation, not vendor pitching to customer

**Approach timing:** After SOAR event — come with case study in hand

**Pitch:**
> "I run SOAR, an affiliated BRCA club. I've built a booking and race management platform that SOAR is now using. Other clubs are interested. I'd like to discuss whether BRCA would be open to a data sharing arrangement for membership verification, and whether there's an opportunity for BRCA to recommend the platform to affiliated clubs."

**Goals from BRCA conversation:**
1. API or periodic data export for membership number verification
2. BRCA recommending platform to affiliated clubs (distribution)
3. Eventually: results feeding into national standings

**Fallback options if no API:**
- Self-declaration + annual renewal prompt (flag unverified after 1st January each year)
- Club-level verification (club admins mark BRCA membership as verified for their members)

---

### Driver Check-in Feature (Re-added to Backlog)

> Previously on backlog, re-confirmed this session

**Concept:** Driver arrives at track, checks in on phone via:
- QR code scan (club prints/displays QR at gate)
- GPS geofence (app detects they're at venue, offers check-in automatically)

**What check-in does:**
- Confirms attendance against booking list
- Timestamps arrival
- Notifies race control driver is on site
- Could trigger driver briefing notifications
- Feeds into transponder matching for results eventually

**Why it matters for business:**
- Makes platform visible and tangible on race day — not just "a website where you booked"
- Habit-forming — clubs that use it won't go back to paper registers
- Compelling demo content for YouTube and club acquisition

**Spec to confirm:**
- [ ] QR preference vs GPS vs both?
- [ ] What does race control view show — arrived list, class breakdown, outstanding bookings?

---

### Event Directory — Scraping BRCA Calendar

> New strategic feature — makes RC Misfits definitive UK RC event directory

**Concept:** Background job periodically scrapes BRCA event calendar and RC-Results event schedules, creates draft event listings on RC Misfits automatically. Clubs don't need to know we exist for their events to appear.

**Why this matters:**
- Racers find events on RC Misfits → habit forms → they push their clubs to join
- SEO — "RC car racing events near [city]" returns RC Misfits
- Inbound leads — club secretaries notice their events are listed and enquire about full platform
- Becomes the Skyscanner/Trainline of UK RC racing

**Implementation:**
- [ ] BRCA calendar scraper background job
- [ ] RC-Results event schedule scraper
- [ ] Auto-create draft events from scraped data (venue matched by name, manual review for new venues)
- [ ] "Claim this event" flow for club admins who find their events listed

