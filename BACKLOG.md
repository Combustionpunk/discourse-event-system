# Discourse Event System — Project Backlog
> Plugin: `discourse-event-system` (RC Bookings for Misfits Discourse)
> Repo: `https://github.com/combustionpunk/discourse-event-system`
> Last updated: 2026-04-25

---

## Working Method
- Planning & discussion happens in Claude.ai chat
- Claude.ai produces prompts → pasted into Claude Code for file edits
- Claude Code commits and pushes: `cd /workspace/discourse/plugins/discourse-event-system && git push`
- Live deploy: SSH into live server → `cd /var/discourse && ./launcher rebuild app`
- Plugin is pulled from GitHub during rebuild (configured in `/var/discourse/containers/app.yml`)

---

## Recently Completed

### UI Improvements
- [x] **F Grade & T Grade on Racing Profile** — dropdowns (0–5) added to My Racing Profile page, saved/loaded via API, used in CSV export as "Formula Number"
- [x] **Guardian / Dependant system** — users can set a parent/guardian; guardians can book events on behalf of dependants
- [x] **Family member management** — add existing users or create new accounts for dependants, edit DOB & BRCA number, view login credentials for newly created accounts

### CSV Export (RCTiming)
- [x] **Export CSV from event manage page** — downloads entries as `.csv` for import into RCTiming software
- [x] **Member Type Number column** — renamed from `Member Type` to `Member Type Number` (values: 1=junior member, 2=adult member, 3=non-member)
- [x] **Formula Number column** — pulls F Grade from user custom field `des_f_grade`
- [x] **Current CSV columns** (in order):
  `Name, BRCA Number, Class, PT No, Car Make, Paid Status, Formula Number, Member Type Number`

### Venues
- [x] **Venues system** — create/manage venues with full details (address, facilities, track info, parking, etc.)
- [x] **Venue assigned to events** — events can be linked to a venue

### Other
- [x] Organisations & membership types with PayPal payments
- [x] Event bookings with waitlist, cancellations, refunds
- [x] Garage (cars, manufacturers, transponders)
- [x] Badge system (First Start, Regular Racer, etc.)
- [x] Email notifications for bookings, cancellations, membership expiry
- [x] Admin panel (`/des-admin`) for site-wide management

---

## Active / In Progress

### RCTiming CSV — Verify & Test
- [ ] Test the CSV import into RCTiming software on a real event
- [ ] Confirm column names and order match exactly what RCTiming expects
- [ ] Confirm `Member Type Number` values (1/2/3) are correct for RCTiming
- [ ] Confirm `PT No` (transponder) format is correct
- [ ] Any additional columns RCTiming needs?

---

## Backlog (To Do)

> Add items here as we discuss them. Priority order top to bottom.

### High Priority
- [ ] **TBD** — add items from memory of previous discussions

### Medium Priority
- [ ] **TBD**

### Low Priority / Nice to Have
- [ ] **TBD**

---

## Known Issues / Bugs
- [ ] Add any known bugs here

---

## Conventions & Decisions
- Junior age threshold: **under 16** at event start date
- Member Type Numbers: `1` = junior member, `2` = adult member, `3` = non-member
- F Grade / T Grade range: `0–5`
- BRCA number defaults to `0` if not set in CSV export
- Transponder defaults to `0` if not set in CSV export
- Plugin uses `des_` prefix for all models and custom fields
- Custom user fields: `brca_membership_number`, `des_date_of_birth`, `des_f_grade`, `des_t_grade`
- PayPal used for payment processing (membership & event bookings)
- Discourse Docker deploy — no direct file access on live server, always rebuild
