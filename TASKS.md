# Service Reminder — Task Tracker

> Update status as you go: `[ ]` pending · `[x]` done · `[-]` skipped / dropped
> Last updated: 2026-04-07

---

## IN PROGRESS / HALF DONE

_Nothing currently half-done._

---

## DASHBOARD & DAILY WORKFLOW

- [ ] Today's summary header — "5 visits today · 2 done · 1 overdue"
- [ ] Search bar on dashboard to find a customer's visit quickly
- [ ] Sort / filter visits by status, time, or customer type
- [ ] Quick note on a visit (without completing it)
- [ ] Call log on card — show "Called at 10:30 am" after tapping call
- [ ] Swipe to call / swipe to complete for faster actions

---

## CUSTOMER MANAGEMENT

- [ ] Open customer address in Google Maps (one-tap navigation)
- [ ] WhatsApp reminder button on customer card — "Your service is due"
- [ ] Customer tags / labels — "VIP", "Difficult", "New area"
- [ ] Bulk WhatsApp / SMS reminders to all overdue customers at once
- [ ] Customer notes field — "Gate code: 1234", "Call before coming"
- [ ] Import customers from phone contacts
- [ ] Inactive customer alert — not serviced in 6+ months
- [ ] Customer lifetime value — total paid, since when, loyalty indicator

---

## REPORTING & ANALYTICS

_Reports page already has: earnings chart, services chart, KPI cards, top customers, completed services list._

- [ ] Completion rate % — assigned vs actually completed
- [ ] Reschedule rate — which customers reschedule most
- [ ] Revenue breakdown by service type
- [ ] Monthly growth trend line chart
- [ ] Best day of week for services
- [ ] Cancelled visits analysis (reason from reschedule notes)
- [ ] AMC vs one-time revenue split
- [ ] Export reports as PDF or Excel
- [ ] Yearly summary view

---

## NOTIFICATIONS & REMINDERS

- [x] Local push notification — morning briefing daily at 8:00 AM
- [x] Before-visit alert — 30 min before each scheduled visit
- [x] Notifications auto-sync on every dashboard refresh (cancel on complete/cancel)
- [x] Permission request + morning briefing toggle on Account/Profile page
- [ ] Overdue visit alert — "Visit overdue by 2 hours"
- [ ] Customer due-soon alert — "5 customers due this week"
- [ ] In-app notification bell with activity feed

---

## SERVICE COMPLETION

- [ ] Before / after photo capture during service
- [ ] Digital signature from customer on completion
- [ ] PDF receipt / invoice generation (shareable via WhatsApp)
- [ ] Parts used / materials log — filter type, membrane brand etc.
- [ ] Service checklist customization per service type
- [ ] Next service auto-reminder SMS to customer after completion

---

## UX & APP QUALITY

- [ ] Dark mode
- [ ] Offline mode — queue actions, sync when online
- [ ] Biometric lock — fingerprint / face ID to open app
- [ ] App onboarding tour for new users (first launch)
- [ ] Undo cancel / delete — 5-second snackbar undo
- [ ] Multiple language support — Hindi, regional languages

---

## ACHIEVEMENTS & MILESTONES

Full gamification system to celebrate progress.

### Service Count Badges
- [ ] 1st service — "First Wrench" — confetti + "Your journey begins!"
- [ ] 10 services — "Getting Started" — gold star burst
- [ ] 25 services — "On a Roll" — green celebration banner
- [ ] 50 services — "Half Century" — big confetti
- [ ] 100 services — "Century!" — full-screen celebration, "You're a Pro!"
- [ ] 250 services — "Service Expert" — trophy icon + shareable card
- [ ] 500 services — "Master Technician" — animated trophy + stats
- [ ] 1000 services — "Legend" — rare badge + special profile border

### Streak Badges
- [ ] 7 days in a row with at least 1 service — "Week Warrior"
- [ ] 30 days with zero overdue visits — "Zero Overdue Month"
- [ ] 5 services in a single day — "Busy Day"
- [ ] Best month ever (personal record) — "Personal Best 🏆"

### Business Milestone Badges
- [ ] First ₹1,000 earned — "First Earnings"
- [ ] ₹10,000 in a single month — "10K Month"
- [ ] ₹1,00,000 total earned — "Lakhpati 🎉"
- [ ] First AMC customer — "First Contract"
- [ ] 10 AMC customers — "AMC Pro"
- [ ] 50 total customers — "Growing Business"
- [ ] 100 total customers — "Established"

### Achievement UI to build
- [ ] Confetti animation on milestone hit (use `confetti` package)
- [ ] Achievement popup — icon, badge name, stat, share button
- [ ] Achievement shelf on Profile page — all earned badges displayed
- [ ] Progress bar toward next milestone — "74 of 100 services · 26 to go"
- [ ] Shareable achievement card image (WhatsApp / Instagram)

---

## SMART / ADVANCED FEATURES

_Longer-term, higher-effort ideas._

- [ ] Area clustering — group visits by neighbourhood for efficient routing
- [ ] Service interval intelligence — learn each customer's real schedule
- [ ] Seasonal reminder boost — auto-increase frequency in summer months
- [ ] Part replacement tracker — "Membrane last changed 14 months ago"
- [ ] Revenue forecasting — "Estimated next month from AMC: ₹X"
- [ ] Complaint / feedback log — shows on card before next visit
- [ ] Multi-technician support — assign visits to staff, track their work

---

## COMPLETED

_Move items here with `[x]` when done._

- [x] Green call button on dashboard visit card
- [x] Reschedule option added to cancel dialog (Keep / Reschedule / Cancel)
- [x] Reschedule dialog — date picker, time picker, reason text field
- [x] `rescheduleVisit()` in provider and data layer — saves new date/time + note
- [x] Profile page — shows email, avatar, sign-out with confirmation
- [x] Account tab added to bottom navigation bar
- [x] Phone OTP login — full 2-step flow (send OTP → enter code → verify)
- [x] Email/password login cleaned up (removed dead OTP tab, fixed subtitle)
- [x] Email confirmation check removed — signup logs in immediately
- [x] Login / signup pages no longer double-navigate (GoRouter handles redirect)
- [x] Reschedule note shown on dashboard visit card (amber banner with reason)
- [x] Reschedule history section in customer service history page (timeline view)
- [x] `getAssignmentsForCustomer` added to full data layer + provider
- [x] Local push notifications — flutter_local_notifications + timezone wired end-to-end
