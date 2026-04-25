# Discourse Event System — Project Backlog
> Plugin: `discourse-event-system` (RC Bookings for Misfits Discourse)
> Repo: `https://github.com/Combustionpunk/discourse-event-system`
> Last updated: 2026-04-26

---

## Working Method
- Planning & discussion happens in Claude.ai chat (this Project)
- Claude.ai produces prompts → pasted into Claude Code for file edits
- Claude Code commits and pushes: `cd /workspace/discourse/plugins/discourse-event-system && git push`
- Test locally first, then deploy live
- Live deploy: SSH into live server → `cd /var/discourse && ./launcher rebuild app`
- Plugin is pulled from GitHub during rebuild (configured in `/var/discourse/containers/app.yml`)
- At end of each session: update BACKLOG.md, commit and push

---

## Recently Completed

### RC Results Integration — Phase 1 (Fields)
- [x] RC Results Venue ID field on Organisation settings
- [x] RC Results Meeting ID field on Event manage page
- [x] Both fields save and persist correctly

### RC Results Integration — Phase 2 (Results Import & Display)
- [x] Results scraper service — fetches finals from rc-results.com by meeting ID
- [x] Scraper correctly identifies finals by race name (containing "Final")
- [x] SSL + timeout support added to HTTP requests in scraper
- [x] 4 new DB tables: des_event_results, des_event_result_races, des_event_result_entries, des_event_result_class_summaries
- [x] Results controller with import, match, publish actions
- [x] Driver auto-matching (by name against username/display name)
- [x] Results tab on event manage page (championship round events only)
- [x] Import Results button — scrapes and stores results
- [x] Match confirmation UI — shows all races and entries, admin can assign usernames
- [x] Publish Results & Award Badges — builds class summaries, awards badges
- [x] Badges: {OrgName} Gold, {OrgName} Silver, {OrgName} Bronze, {OrgName} Fastest Lap
- [x] Public event page results section (championship rounds only)
- [x] Podium cards — top 3 per class with avatar, trophy icon, clickable username
- [x] Unmatched drivers show ? icon with RC Results name
- [x] Full finals results tables below podium cards
- [x] Fastest lap per class shown on podium card (excludes 0.00 lap times)
- [x] Heading: "Championship Round Results"
- [x] "Awaiting event results" shown before import on championship round events
- [x] Results CSS styling

### CSV Export (RCTiming) — Previous Sessions
- [x] Member Type Number with 4 values (junior/adult x member/non-member)
- [x] No DOB defaults to senior

### Bug Fixes — Previous Sessions
- [x] Manage Event button visible to admins regardless of booking status
- [x] Family-only booking fixed (multiple fixes)
- [x] RC Results Meeting ID saving correctly

---

## Backlog (To Do)

### High Priority
- [ ] **Membership creation restriction** — only organisation officials should be able to create memberships manually on the organisation page

### Medium Priority
- [ ] **RC Results Phase 3** — transponder/BRCA number matching for driver auto-match (currently name-only)
- [ ] **Re-publish results** — if re-importing after publish, badges should not be double-awarded
- [ ] **Results on event manage** — show published results summary on manage page

### Low Priority / Nice to Have
- [ ] **RC Results live view** — link to live race page during an event
- [ ] **Season standings** — aggregate results across multiple championship rounds

---

## Known Issues / Bugs
- [ ] Badge double-award possible if results are re-published — needs guard check before BadgeGranter.grant

---

## Conventions & Decisions
- Junior age threshold: **under 16** at event start date
- Member Type Numbers: `1` = junior member, `2` = adult member, `3` = junior non-member, `4` = adult non-member
- No DOB set → defaults to senior (adult)
- F Grade / T Grade range: `0–5`
- BRCA number defaults to `0` if not set in CSV export
- Transponder defaults to `0` if not set in CSV export
- Plugin uses `des_` prefix for all models and custom fields
- Custom user fields: `brca_membership_number`, `des_date_of_birth`, `des_f_grade`, `des_t_grade`
- PayPal used for payment processing
- RC Results Venue ID 1075 = Sheffield Off Road & Rally RCC (SOAR)
- Championship round events = events with event type name containing "championship"
- Podium = A Final positions 1, 2, 3 per class
- Fastest lap = fastest non-zero best_lap across ALL finals for the class
- Badges are per-organisation: "{OrgName} Gold", "{OrgName} Silver", "{OrgName} Bronze", "{OrgName} Fastest Lap"
- Discourse Docker deploy — no direct file access on live server, always rebuild
