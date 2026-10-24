# Feature Specification: Kid Timer (v1.0 and v1.x)

**Feature Branch**: `001-visual-timer`

**Created**: 2026-10-23

**Status**: Planned — tasks generated and analyzed

**Input**: User description: "A free, open source visual timer for children, strongly inspired
by (but not a clone of) Fehners Software's Visual Countdown Timer. Universal: phone, tablet and
PC. Scope up to version 1.x. The first version MUST ship with a built-in image library and allow
using one's own image from the device; with no image selected, the dial uses colors."

## Overview

An adult (parent, caregiver, teacher or therapist) sets a time; the child sees a dial that
shrinks as time passes. The dial shows an image (from the built-in library or from the device)
or, without an image, a color. When time is up, a celebration screen appears and stays until
someone taps. The alarm rings even with the app closed. There are no ads, accounts, internet or
data collection.

**Personas**

- **Configuring adult**: parent, caregiver, teacher or therapist. Sets up timers, images,
  presets and routines. Uses a phone, tablet, PC or projector.
- **Observing child**: 3 to 12 years old, may have ADHD, autism or reading difficulties. Only
  watches the dial; must not be able to change the timer.

**Releases**

| Release    | Stories     |
| ---------- | ----------- |
| v1.0 (MVP) | US1 to US7  |
| v1.x       | US8 to US14 |

## Clarifications

### Session 2026-10-23

Decisions taken with the options recommended by `/speckit-clarify`; the product owner may
revise them before implementation.

- Q: How does the image appear on the dial during the countdown? → A: The remaining part of the
  dial is filled with the image cropped to a circle; the elapsed part shows a translucent
  neutral tone. The image "disappears" as time passes. Without an image, the remaining sector
  uses the configured color or palette.
- Q: Which gesture unlocks the controls during the countdown? → A: Press and hold a discreet
  padlock icon in the top corner for 3 s; a progress ring shows the hold time. On a keyboard,
  hold the Esc key for 3 s.
- Q: What is the parental gate challenge? → A: A multiplication of two numbers from 3 to 9
  written out in words (e.g., "seven times eight"), answered on a numeric keypad; 3 wrong
  answers in a row lock it for 30 s.
- Q: What duration range is allowed? → A: v1.0: 10 s to 2 h. v1.x: up to 12 h using multiple
  dials.
- Q: What is the minimum size of the v1.0 image library? → A: At least 36 images in 6 activity
  categories (hygiene, meals, play, rest, school, going out), all with compatible licenses and
  appropriate for children.
- Q: How is one's own image framed? → A: Circular crop with simple position and zoom adjustment
  (drag and pinch, or buttons) before saving.
- Q: How many own images can be stored? → A: Up to 50; when the limit is reached, the app asks
  the adult to delete one in "My images".
- Q: What happens where the system cannot ring an alarm with the app closed (Web, Linux)? → A:
  A persistent notice "Keep this window open to hear the alarm" appears before starting and on
  the countdown screen (outside the child lock, visible only to the adult when unlocked).

### Session 2026-10-24

- Q: Can the library hold images that are not activities? → A: Yes: a seventh category,
  animals (dog, cat, rabbit…), for children who like to see a favorite animal on the dial. It
  follows the same license and review rules; the six activity categories stay as they are.
- Q: Should the whole Fluent Emoji set be available, not only a curated selection? → A: Yes, as
  an extended library (US15), bundled in the app so it works offline with no network
  (Constitution I). A committed denylist removes content unsuitable for children before a
  per-group human review (Constitution II, v1.2.0). People appear in the neutral yellow, with
  the five skin tones offered on the image.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Visual countdown with a shrinking dial (Priority: P1) — v1.0

The adult chooses a duration by dragging the dial or tapping quick buttons, starts the timer and
the child watches the dial shrink to zero. At the end, a celebration screen with sound and
vibration appears and only goes away when someone taps. The adult can pause, resume, restart or
cancel.

**Why this priority**: It is the core of the product; nothing else has value without it.

**Independent Test**: Open the app, set 2 minutes by dragging the dial, start, watch the dial
shrink to zero and see the final screen stay until a tap.

**Acceptance Scenarios**:

1. **Given** the app open on the home screen, **When** the adult drags the dial's edge to the
   5 min mark, **Then** the displayed time is 05:00 and the dial sector covers 5 min of the
   scale.
2. **Given** a set time, **When** the adult taps +1 min or +5 min, **Then** the time increases
   by that amount without exceeding the allowed maximum.
3. **Given** a 1 min timer started, **When** 30 s pass, **Then** the remaining sector
   corresponds to 30 s (1 s tolerance) and, if digits are on, shows 00:30.
4. **Given** a running timer, **When** the adult pauses and resumes after 20 s, **Then** the
   remaining time equals the time at the moment of pausing.
5. **Given** a timer reaching zero with the app open, **When** time is up, **Then** the chosen
   sound plays, the device vibrates (if available and enabled) and the final screen appears.
6. **Given** the final screen visible, **When** nobody taps for 10 minutes, **Then** it remains
   visible; **When** someone taps, **Then** the app returns to the home screen with the last
   time used.
7. **Given** a running timer, **When** the adult cancels, **Then** the countdown stops, no alarm
   rings later and the app returns to the home screen.
8. **Given** the "show digits" option off, **When** the timer runs, **Then** only the dial is
   shown, without digits.

---

### User Story 2 - Reliable alarm and screen always on (Priority: P1) — v1.0

The timer finishes and rings even if the app is minimized, killed by the system or the screen
locks. During the countdown with the app open, the screen does not turn off. On reopening, the
app shows the correct state.

**Why this priority**: A children's timer that does not ring breaks trust; it is the biggest
complaint about similar apps.

**Independent Test**: Start 1 min, lock the screen, wait and confirm the alarm; reopen and see
the final screen.

**Acceptance Scenarios**:

1. **Given** a 1 min timer on an Android/iOS phone or tablet or on macOS, **When** the app goes
   to the background or the screen locks, **Then** the alarm rings at the end within 5 s.
2. **Given** a running timer, **When** the system kills the app and time runs out, **Then** the
   alarm rings; **When** the adult reopens the app, **Then** the final screen is shown.
3. **Given** a running timer and the app reopened before the end, **When** the home screen
   loads, **Then** the countdown continues exactly from the real remaining time.
4. **Given** a running timer with the app in the foreground, **When** more minutes pass than the
   device's auto-lock time, **Then** the screen stays on.
5. **Given** Android 14+ without the exact alarm permission, **When** the adult starts a timer,
   **Then** the app explains why and offers to open the "Alarms & reminders" setting; if the
   adult declines, the timer works in the foreground and the reduced-accuracy notice is shown.
6. **Given** notifications disabled by the adult in the system, **When** a timer starts,
   **Then** the app warns that the alarm will only ring with the app open and offers to open
   the settings.
7. **Given** Web or Linux, **When** the adult starts a timer, **Then** the "Keep this window
   open" notice appears and the alarm rings normally with the window open.
8. **Given** the system clock changes time zone during the countdown, **When** the timer
   finishes, **Then** the real perceived duration is the configured one.

---

### User Story 3 - Image on the dial: built-in library and own image (Priority: P1) — v1.0

The adult chooses an image for the timer from the app's built-in library (organized by activity,
plus animals) or a photo from the device. The image fills the dial and "disappears" as time
passes. Without an image, the dial uses colors.

**Why this priority**: Mandatory v1.0 requirement; images make the activity concrete for young
children and non-readers.

**Independent Test**: Pick the "brush teeth" image from the library, start 1 min and watch the
image disappear with the dial; then pick a device photo, frame it and repeat; finally remove the
image and see the colored dial.

**Acceptance Scenarios**:

1. **Given** the home screen, **When** the adult opens "Choose image", **Then** they see the
   built-in library grouped into 7 categories, working without internet.
2. **Given** the picker open, **When** the adult chooses a library image, **Then** it appears on
   the dial immediately, cropped to a circle.
3. **Given** the picker open, **When** the adult taps "From my device", **Then** the system
   picker opens without asking for access to all files or photos.
4. **Given** a photo chosen from the device, **When** the adult adjusts position and zoom and
   confirms, **Then** the image is saved to "My images" and applied to the dial.
5. **Given** a photo with location metadata, **When** it is saved in the app, **Then** the
   stored copy contains no metadata (EXIF/GPS).
6. **Given** a timer with an image running, **When** half the time passes, **Then** half the
   dial shows the image and the other half shows the neutral "elapsed time" tone.
7. **Given** a timer with an image, **When** the adult taps "No image", **Then** the dial goes
   back to the configured colors.
8. **Given** 50 own images saved, **When** the adult tries to add another, **Then** the app
   reports the limit and takes them to "My images" to delete one.
9. **Given** an own image used by a preset, **When** the adult deletes it, **Then** the app
   warns which presets will be affected and, on confirmation, those presets switch to colors.
10. **Given** the chosen file is not a valid image or is corrupted, **When** the app tries to
    load it, **Then** it shows a friendly message and nothing is saved.

---

### User Story 4 - Child lock and full screen (Priority: P2) — v1.0

During the countdown the screen enters child mode: full screen, no visible buttons, no response
to ordinary touches. To interact, the adult holds the padlock for 3 s.

**Why this priority**: Children pause or cancel timers by accident; competing apps fail here.

**Independent Test**: Start a timer, tap the screen many times with no effect, hold the padlock
for 3 s and see the controls appear.

**Acceptance Scenarios**:

1. **Given** the child lock on (default), **When** the timer starts, **Then** the screen goes
   full screen, the controls disappear and only a discreet padlock remains visible.
2. **Given** child mode active, **When** someone taps, drags or double-taps, **Then** nothing
   happens besides a slight glow on the padlock.
3. **Given** child mode active, **When** the adult holds the padlock for 3 s, **Then** a progress
   ring completes and the controls appear for 10 s before locking again.
4. **Given** the adult releases the padlock before 3 s, **When** the ring has not completed,
   **Then** the controls do not appear and the ring resets.
5. **Given** desktop or web with a keyboard, **When** the adult holds Esc for 3 s, **Then** the
   controls appear, same as the padlock.
6. **Given** the child lock disabled in settings, **When** the timer runs, **Then** the controls
   are always visible.
7. **Given** Android, **When** the adult wants to use the system's "Screen pinning", **Then** the
   app shows, in settings, how to use that feature to prevent leaving the app.

---

### User Story 5 - Activity presets (Priority: P2) — v1.0

The adult saves combinations of name, duration, image or color and sound as presets ("Brush
teeth – 2 min") and starts them with one tap.

**Why this priority**: Reduces daily friction; teachers complained about recreating timers.

**Independent Test**: Create the preset "Brush teeth – 2 min" with an image, close the app,
reopen it and start the preset with one tap.

**Acceptance Scenarios**:

1. **Given** a configured timer, **When** the adult taps "Save as preset" and gives it a name,
   **Then** the preset appears in the list with thumbnail, name and duration.
2. **Given** the preset list, **When** the adult taps a preset, **Then** the timer is set to its
   values and can be started with one more tap.
3. **Given** the list, **When** the adult edits, duplicates, reorders or deletes a preset,
   **Then** the change persists after closing and reopening the app.
4. **Given** the first use of the app, **When** the preset list opens, **Then** there are 6
   example presets (one per activity category of the library; none for animals), which can be
   deleted.
5. **Given** an empty name or one longer than 40 characters, **When** the adult tries to save,
   **Then** the app explains the rule and does not save.
6. **Given** 100 saved presets, **When** the adult tries to create another, **Then** the app
   reports the limit.

---

### User Story 6 - Appearance, sound and preferences (Priority: P2) — v1.0

The adult adjusts the dial scale (5, 10, 15, 30, 60 or 120 min), rotation direction, color
palette (progressive, single color or calm mode), show digits, alarm sound, volume, ticking,
vibration and light/dark theme.

**Why this priority**: Every child reacts differently; calm mode and sound control address
recurring complaints (red that causes anxiety, loud ticking).

**Independent Test**: Turn on calm mode and turn off ticking, start 1 min and confirm there is
no red and no ticking.

**Acceptance Scenarios**:

1. **Given** the progressive palette, **When** the remaining time goes from 50% to 20% and then
   below 20%, **Then** the image-less dial changes from green to yellow and then red, with a
   smooth transition.
2. **Given** calm mode, **When** the timer runs, **Then** no red or alert color is used and
   transitions are in pastel tones.
3. **Given** a single color chosen, **When** the timer runs, **Then** the dial keeps that color.
4. **Given** a 60 min scale, **When** the adult sets 15 min, **Then** the dial covers a quarter
   of the circle; with a 15 min scale, the same 15 min cover the whole circle.
5. **Given** counter-clockwise direction, **When** the timer runs, **Then** the dial shrinks in
   the direction opposite to the default.
6. **Given** the sound list, **When** the adult taps a sound, **Then** they hear a preview at the
   configured volume.
7. **Given** ticking on with low volume, **When** the timer runs with the app open, **Then** the
   tick sounds every second; when off, there is no sound until the end.
8. **Given** the "follow system" theme, **When** the system switches to dark, **Then** the app
   switches to dark while keeping at least AA contrast.
9. **Given** any changed preference, **When** the app is reopened, **Then** the preference is
   still applied.

---

### User Story 7 - Accessibility, languages and parent area (Priority: P2) — v1.0

The app works with screen readers, keyboard, large fonts and reduced motion; it is in Brazilian
Portuguese and English; the parent area ("About", licenses, privacy, source code) sits behind
the parental gate.

**Why this priority**: The audience includes children and adults with disabilities; store
requirement for children's apps.

**Independent Test**: With TalkBack or VoiceOver, set up and start a timer using only voice and
accessibility gestures; switch the system language to English and see the whole interface
translated; open "About" and solve the parental gate.

**Acceptance Scenarios**:

1. **Given** an active screen reader, **When** the adult navigates the home screen, **Then**
   every control announces name, role and value (e.g., "Duration, 5 minutes, adjustable").
2. **Given** a running timer with a screen reader, **When** each minute passes, **Then** the
   remaining time is announced at most once per minute (configurable interval: 1, 5 min or
   off).
3. **Given** the system font at 200%, **When** any screen is opened, **Then** no text is
   clipped and no control becomes unreachable.
4. **Given** "reduce motion" active in the system, **When** the timer finishes, **Then** the
   celebration uses only opacity transitions, without spins or particles.
5. **Given** desktop or web, **When** the adult uses only the keyboard, **Then** every control is
   reachable with Tab, has visible focus and responds to Enter/Space; arrow keys adjust the
   duration.
6. **Given** the system language in English, **When** the app opens, **Then** the whole
   interface is in English; in any other unsupported language, the app uses English; in
   Portuguese, pt-BR.
7. **Given** the adult taps "About", **When** the parental gate appears and the answer is
   correct, **Then** the parent area opens with version, licenses, privacy policy and a link to
   the source code.
8. **Given** 3 wrong answers in a row on the parental gate, **When** the child tries again,
   **Then** the gate is locked for 30 s.
9. **Given** an external link in the parent area, **When** it is tapped, **Then** the app asks
   for confirmation before opening the browser.

---

### User Story 8 - Routines in sequence (Priority: P3) — v1.x

The adult builds routines such as "Morning: wake up → get dressed → breakfast → brush teeth →
backpack", each step with an image and duration. The child sees the current step on the dial
and the sequence on a strip of pictograms; completing each step earns a star.

**Why this priority**: Great value for routines and ADHD; depends on the finished core.

**Independent Test**: Create a 3-step routine of 30 s each, run it in automatic mode and see the
3 alarms, the step changes and the 3 stars.

**Acceptance Scenarios**:

1. **Given** the routines screen, **When** the adult creates a routine with a name and 2 to 20
   steps (each with name, duration and image or color), **Then** it is saved and listed.
2. **Given** a routine in automatic mode, **When** a step finishes, **Then** a short transition
   sound plays and the next step starts on its own.
3. **Given** a routine in manual mode, **When** a step finishes, **Then** a big "Next" button
   appears and the next step only starts when it is tapped.
4. **Given** a running routine, **When** the child looks at the screen, **Then** they see the
   "now / next" strip with the current step highlighted and finished ones marked with a star.
5. **Given** a running routine with the app closed, **When** each step finishes, **Then** the
   step notification rings (in automatic mode) with the name of the next step.
6. **Given** the routine finished, **When** the last step ends, **Then** the final celebration
   appears with all the stars.
7. **Given** a "First / Then" template, **When** the adult picks two images, **Then** a 2-step
   routine is created with a side-by-side layout.

---

### User Story 9 - Intermediate warnings (Priority: P3) — v1.x

The adult enables warnings before the end (e.g., 5 min left and 1 min left) with soft sound and
vibration, to prepare the transition.

**Why this priority**: Helps difficult transitions; simple on top of the core.

**Independent Test**: A 3 min timer with a "1 min left" warning; hear the warning at 2 min and
the alarm at 3 min, also with the app closed.

**Acceptance Scenarios**:

1. **Given** warnings at 5 and 1 min, **When** 5 min and then 1 min remain, **Then** a soft sound
   different from the final alarm plays and the dial pulses gently once.
2. **Given** a warning greater than or equal to the timer's duration, **When** the timer starts,
   **Then** that warning is ignored.
3. **Given** the app closed, **When** a warning is due, **Then** a silent or softly sounding
   notification is shown.

---

### User Story 10 - Image reveal effects (Priority: P3) — v1.x

Besides "the image disappears", the adult can choose effects: "the image appears" (reveal),
mosaic and puzzle.

**Why this priority**: Increases motivation; not essential.

**Independent Test**: Choose "puzzle" and watch pieces of the image appear over 1 min until the
full image at the end.

**Acceptance Scenarios**:

1. **Given** the "reveal" effect, **When** the timer runs, **Then** the elapsed sector shows the
   image and the remaining sector shows the neutral tone.
2. **Given** the "mosaic" effect, **When** the timer runs, **Then** the image becomes
   progressively sharper in at least 10 steps.
3. **Given** the "puzzle" effect with 9 pieces, **When** the timer runs, **Then** one piece
   appears every 1/9 of the time, in a pseudo-random order that is stable for the same timer.
4. **Given** "reduce motion" active, **When** any effect occurs, **Then** transitions are
   instantaneous or opacity-only.

---

### User Story 11 - Long timers with multiple dials (Priority: P3) — v1.x

For durations above the maximum scale, the app shows one dial per hour (or per scale), up to
12 h.

**Why this priority**: Useful in classrooms and on trips; less frequent use.

**Independent Test**: Set 2 h 30 min and see two full dials and one half-scale dial.

**Acceptance Scenarios**:

1. **Given** a 60 min scale and a 2 h 30 min duration, **When** the timer starts, **Then** 3
   dials appear and they empty one at a time, from right to left.
2. **Given** a 12 h duration, **When** the adult tries to increase it, **Then** the app does not
   allow it.
3. **Given** a compact screen, **When** there are more than 4 dials, **Then** they fit in a grid
   without scrolling.

---

### User Story 12 - Widgets and system-level alarm (Priority: P3) — v1.x

The adult adds a home screen widget (Android/iOS) with favorite presets that start with one tap.
On iOS 26+, the alarm breaks through silent mode and shows the countdown on the lock screen and
in the Dynamic Island.

**Why this priority**: Extra convenience and reliability; requires native code.

**Independent Test**: Add the widget, tap the "Brush – 2 min" preset, see the app open already
counting down; on iOS 26+, with the iPhone on silent, hear the alarm.

**Acceptance Scenarios**:

1. **Given** a widget with up to 4 favorite presets, **When** the adult taps one, **Then** the
   app opens already counting down that preset.
2. **Given** a running timer, **When** the adult looks at the widget, **Then** it shows the
   active preset and the end time.
3. **Given** iOS 26+ with alarm consent granted, **When** the timer finishes with the device on
   silent, **Then** the alarm rings.
4. **Given** iOS 26+, **When** the timer runs, **Then** the lock screen and the Dynamic Island
   show the countdown.
5. **Given** iOS earlier than 26 or consent denied, **When** the timer finishes, **Then** the
   behavior is that of US2 (local notification).

---

### User Story 13 - Export and import presets and routines (Priority: P3) — v1.x

The adult exports presets and routines (optionally with own images) to a file and imports it on
another device, with no server.

**Why this priority**: Teachers and therapists share setups; privacy is preserved.

**Independent Test**: Export 3 presets and 1 routine on a phone, import on the PC and use them.

**Acceptance Scenarios**:

1. **Given** saved presets and routines, **When** the adult exports with "include my images",
   **Then** a single file is generated and the system save/share sheet opens.
2. **Given** an exported file, **When** the adult imports it, **Then** they see a preview of the
   content and choose "add" or "replace".
3. **Given** an invalid, corrupted or future-version file, **When** the adult imports it,
   **Then** the app explains the problem and nothing is changed.
4. **Given** an imported preset with the same name as an existing one, **When** the import is
   "add", **Then** the imported one gets the suffix " (2)".

---

### User Story 14 - Additional themes, palettes and languages (Priority: P3) — v1.x

The adult chooses the high-contrast theme manually (v1.0 already follows the system setting) and palettes safe for color vision deficiency; the
community adds languages through an open translation platform.

**Why this priority**: Broadens inclusion; the basics are already in v1.0.

**Independent Test**: Choose the "color blindness (deuteranopia)" palette and check that the
dial phases are distinguishable in a color blindness simulator.

**Acceptance Scenarios**:

1. **Given** the "high contrast" theme chosen in settings with the system setting off, **When**
   enabled, **Then** all text and icons have a contrast of at least 7:1 (AAA).
2. **Given** palettes for protanopia, deuteranopia and tritanopia, **When** simulated, **Then**
   the three phases of the progressive palette are distinguishable (luminance difference
   ≥ 20%).
3. **Given** a new language 100% translated on the translation platform, **When** the next
   version is released, **Then** the language appears in the app.

---

### User Story 15 - Extended emoji library: browse by group (Priority: P3) — v1.x

Beyond the curated library, the adult can use any image of the Fluent Emoji set (about 1,300
after removing what is unsuitable for children). To keep so many images manageable, the adult
first sees the groups (Animals & nature, Food & drink, Activities…) with a few previews and a
count, opens one, and finds its images arranged in labeled sections; a search by name finds a
specific image in either language. Everything is in the app: nothing is downloaded.

**Why this priority**: Gives children far more choice (their favorite animal, food or toy)
without overwhelming the adult; the curated library already covers the core routines.

**Independent Test**: From "Choose image", open "All emoji", open the "Animals & nature" group,
pick the giraffe and see it on the dial; then search "girafa" and find the same image.

**Acceptance Scenarios**:

1. **Given** the image picker, **When** the adult opens "All emoji", **Then** they see one card
   per group with its name, image count and four preview images, and no image of any group is
   loaded until the group is opened.
2. **Given** a group opened, **When** it appears, **Then** its images are shown in sections by
   subgroup (e.g., "Mammals", "Birds") with the section names visible, and scrolling stays smooth.
3. **Given** an image chosen in a group, **When** the adult taps it, **Then** the picker closes
   and the image fills the dial as with any library image.
4. **Given** the search field in "All emoji", **When** the adult types a name or keyword in
   Portuguese or English (e.g., "girafa", "giraffe"), **Then** the matching images of every group
   are shown, and an empty result says so.
5. **Given** an image of a person or a hand, **When** the adult long-presses it or taps its tone
   button, **Then** the five skin tones are offered, and the chosen tone is the one shown on the
   dial and saved in presets.
6. **Given** any image the denylist removes (weapons, alcohol, religious or political symbols,
   flags, scary figures…), **When** the adult browses or searches, **Then** it never appears.
7. **Given** the app with no network connection at all, **When** the adult browses the extended
   library, **Then** every group and image is available.

---

### Edge Cases

- Zero duration or below 10 s: the start button is disabled with an explanation.
- Timer started and the system clock manually moved forward/backward: remaining time is always
  derived from the end instant and the current system time, so the on-screen countdown jumps
  by the same amount; the system alarm prevails and the app reconciles on resuming or
  reopening. Time zone changes have no effect (the end instant is absolute).
- App reopened hours after a finished timer: shows the final screen only once; after a tap,
  returns home.
- Two timers cannot run at the same time in v1.0; starting another replaces the current one
  after confirmation.
- Device rebooted during the countdown: on Android, the alarm is rescheduled at boot; if the end
  has already passed, the "Timer finished" notification is shown.
- Vendors that kill background apps (Xiaomi, Huawei, Samsung): the app shows, in settings, a help
  page to exempt the app from battery optimization.
- Very large image (e.g., 50 MP) or uncommon format (HEIC): the app resizes to at most 1024 px;
  unsupported formats show a friendly message.
- Own image deleted from the device after import: nothing changes, because the app keeps a copy.
- Storage full while saving an image: friendly message, nothing partial is saved.
- Silent mode on the iPhone (before iOS 26): the alarm with the app closed respects silent mode;
  the app warns the adult the first time.
- System volume at zero with the app open: the app shows a discreet notice to the adult when
  starting.
- Screen rotation and window resizing during the countdown: the dial readjusts without
  restarting the countdown.
- Projector/external display on desktop: full screen covers the current window's monitor; if
  the window is moved to another monitor while in full screen (e.g., with a system shortcut),
  full screen follows it to the new monitor and the dial readjusts without restarting the
  countdown.
- Screen reader turned on in the middle of a countdown: the countdown continues unchanged;
  the next announcement follows the configured interval, and the padlock remains reachable
  (double-tap and hold for 3 s with the screen reader).
- System font at 200% on a compact screen: controls wrap onto several lines, without clipping.
- Data saved in an earlier format: migrated automatically; if migration fails, the original data
  is preserved and the app uses defaults with a notice.
- An extended emoji (US15) no longer shipped, because its group failed a later review or it
  joined the denylist: the dial uses colors, and the home image chip says so once, as for a
  deleted own image.

## Requirements _(mandatory)_

### Functional Requirements

**Timer core (US1)**

- **FR-001**: The app MUST allow setting a duration between 10 s and 2 h (v1.0) by dragging the
  dial's edge, in steps of 1 min (or 10 s below 2 min), and with buttons +1 min, +5 min,
  −1 min.
- **FR-002**: The app MUST display a dial whose remaining sector is proportional to the
  remaining time relative to the chosen scale, updated continuously.
- **FR-003**: The app MUST offer start, pause, resume, restart and cancel.
- **FR-004**: The app MUST display, when enabled, the remaining time as mm:ss (or h:mm:ss).
- **FR-005**: When time is up, the app MUST show the celebration screen, play the chosen sound
  and vibrate when available and enabled; the final screen MUST remain until a tap.
- **FR-006**: The app MUST remember the last duration and configuration used.
- **FR-007**: In v1.0, only one timer MUST be active at a time.

**Reliability (US2)**

- **FR-010**: Remaining time MUST be computed from the end instant, not from accumulated counts.
- **FR-011**: On Android, iOS, iPadOS and macOS, the timer's end MUST be scheduled with the
  system so it rings with the app in the background, killed or with the screen locked.
- **FR-012**: On Windows, the end MUST be scheduled as a system notification when supported;
  otherwise FR-015 applies.
- **FR-013**: The timer state MUST be saved on every change and restored when the app reopens.
- **FR-014**: With the app in the foreground and the timer running, the screen MUST stay on.
- **FR-015**: On platforms without background alarms (Web, Linux) or with the permission
  denied, the app MUST show the "keep the window open" notice before starting.
- **FR-016**: On Android, the app MUST request and explain the exact alarm and notification
  permissions, and work with reduced accuracy if they are denied.
- **FR-017**: On Android, pending alarms MUST be rescheduled after a reboot.
- **FR-018**: The app MUST offer a help page on battery optimization per vendor.

**Images (US3)**

- **FR-020**: The app MUST include a library of at least 42 images in 7 categories (hygiene,
  meals, play, rest, school, going out, animals), at least 6 per category, available offline.
- **FR-021**: The app MUST allow choosing an image from the device through the system picker,
  without requesting broad storage or gallery permission.
- **FR-022**: Before saving an own image, the app MUST allow framing it in a circle (position and
  zoom).
- **FR-023**: Own images MUST be resized to at most 1024 px on the longest side, have their
  metadata removed and be stored only in the app's storage.
- **FR-024**: The app MUST allow listing and deleting own images ("My images"), with a limit of
  50, warning about affected presets/routines.
- **FR-025**: With an image selected, the dial's remaining sector MUST show the image and the
  elapsed sector MUST show a translucent neutral tone; without an image, it MUST use the color
  palette.
- **FR-026**: Each library image MUST have a localized accessible name (pt-BR and en).

**Child mode (US4)**

- **FR-030**: With the child lock on (default), the countdown MUST run in full screen, with no
  visible controls, ignoring touches and gestures except the unlock.
- **FR-031**: Unlocking MUST require holding the padlock for 3 s (or Esc for 3 s), with a
  progress ring; controls MUST hide after 10 s without interaction.
- **FR-032**: The adult MUST be able to disable the child lock in settings.
- **FR-033**: On Android, the app MUST explain how to use the system's screen pinning.

**Presets (US5)**

- **FR-040**: The adult MUST be able to create, edit, duplicate, reorder and delete presets with
  a name (1 to 40 characters), duration, image or color, sound and scale.
- **FR-041**: Starting a preset MUST take at most two taps from the home screen.
- **FR-042**: The app MUST include 6 example presets on first use, one per activity category of
  the library (not animals); limit of 100 presets.

**Appearance and sound (US6)**

- **FR-050**: The app MUST offer scales of 5, 10, 15, 30, 60 and 120 min and clockwise or
  counter-clockwise direction.
- **FR-051**: The app MUST offer palettes: progressive (green → yellow → red), single color (at
  least 8 colors) and calm mode (no red).
- **FR-052**: The app MUST include at least 8 friendly alarm sounds, with preview, own volume and
  a no-sound option. All bundled sounds MUST be loudness-normalized and free of abrupt onsets
  (measurable targets in research R6).
- **FR-053**: Ticking MUST be optional (off by default) and have its own volume.
- **FR-054**: Vibration MUST be optional on devices that support it.
- **FR-055**: The app MUST offer light, dark and follow-system themes. When the system's
  increase-contrast (high contrast) setting is on, the app MUST switch to a high-contrast
  variant of the current theme in which text and icons reach at least 7:1.
- **FR-056**: Preferences MUST persist across sessions.

**Accessibility, languages and parent area (US7)**

- **FR-060**: All controls MUST have accessible label, role and value; remaining time MUST be
  announced at the configured interval (default: every minute).
- **FR-061**: The app MUST support font scaling up to 200%, full keyboard navigation with
  visible focus and "reduce motion".
- **FR-062**: The whole interface MUST be in pt-BR and en; an unsupported language uses en.
- **FR-063**: Ways out of the app (About, licenses, privacy, source code, links) MUST be behind
  the parental gate described in Clarifications.
- **FR-064**: The app MUST display the privacy policy and the code and asset licenses.
- **FR-065**: The app MUST NOT collect, send or store outside the device any data.

**Routines (US8)**

- **FR-070**: The adult MUST be able to create, edit, duplicate, reorder and delete routines
  with 2 to 20 steps; each step with name, duration, image or color; limit of 100 routines.
- **FR-071**: Routines MUST support automatic and manual advance.
- **FR-072**: Execution MUST show the current step on the dial, the step strip and stars on
  completed steps.
- **FR-073**: In automatic mode, the end of each step MUST be scheduled with the system,
  respecting the platform's limit on pending notifications.
- **FR-074**: The app MUST offer the "First / Then" template.
- **FR-075**: The image library MUST gain activity pictograms for routines, under the same
  license rules as FR-020.

**Warnings, effects, dials (US9–US11)**

- **FR-080**: The adult MUST be able to enable up to 2 warnings, chosen from 1, 2, 5 and 10 min
  before the end, with
  soft sound and vibration, also with the app closed on the FR-011 platforms.
- **FR-081**: The app MUST offer image effects: vanish (default), reveal, mosaic and puzzle (4,
  9 or 16 pieces).
- **FR-082**: The app MUST allow durations up to 12 h, displaying one dial per scale.

**Widgets and system-level alarm (US12)**

- **FR-090**: Android and iOS MUST have a home screen widget with up to 4 favorite presets and
  the active timer's state.
- **FR-091**: On iOS 26+, with consent, the app MUST use the system alarm that rings in silent
  mode and show the countdown on the lock screen and in the Dynamic Island.

**Export and import (US13)**

- **FR-100**: The app MUST export presets and routines, optionally with own images, to a single
  versioned file and import it with a preview, in add and replace modes. Imported own images
  MUST be re-processed under the FR-023 rules (resized, re-encoded, metadata removed) before
  being stored.
- **FR-101**: Import MUST validate the file and be atomic (all or nothing); a file that would
  exceed a limit is rejected as a whole, with an explanation.

**Additional themes and languages (US14)**

- **FR-110**: The app MUST let the adult choose the high-contrast theme (7:1, FR-055) manually,
  independent of the system setting, and offer palettes for protanopia,
  deuteranopia and tritanopia.
- **FR-111**: The project MUST accept community translations through an open platform.

**Extended emoji library (US15)**

- **FR-120**: The app MUST bundle the complete Microsoft Fluent Emoji set, minus the denylist, as
  an extended library available offline beside the curated library (FR-020), with no network
  access (Constitution I).
- **FR-121**: The extended library MUST be browsed in two steps: a list of groups (name, image
  count, four previews), then the group's images in sections by subgroup. Its manifest MUST be
  read only when "All emoji" first opens, off the UI thread, so app start (≤ 2 s,
  Constitution VIII) is unaffected. Opening a group MUST show its first images within 300 ms on
  the reference device and only decode the images on screen.
- **FR-122**: The adult MUST be able to search the whole extended library by name or keyword in
  pt-BR and en, ignoring case and accents.
- **FR-123**: Every extended image MUST have a localized name and keywords in pt-BR and en, from
  the Unicode CLDR annotations (FR-026), kept in the library's manifest as Constitution V allows
  for asset metadata and checked by `tool/l10n_check.dart`.
- **FR-124**: Images that have skin-tone variants MUST appear in the neutral version and offer
  the five tones on the image; the chosen variant is stored with the visual source.
- **FR-125**: Extended images MUST be usable wherever a library image is (dial, presets,
  routines, export), and the curated library MUST remain what the picker shows first.
- **FR-126**: A committed denylist MUST remove unsuitable images before review, and a group MUST
  ship only after an approved per-group human review recorded in `docs/assets-review.md`
  (Constitution II); images the reviewer rejects join the denylist.
- **FR-127**: The extended library MUST add at most 25 MB to the installed app.

### Platform support

Per Constitution VI. ✅ supported · ◐ degraded, with the difference shown in the UI · ✕ not
available (the UI hides the feature or explains it). Technical detail per port in
[contracts/platform-ports.md](./contracts/platform-ports.md).

| Feature                                      | Android                 | iOS/iPadOS                  | macOS          | Windows           | Linux              | Web                     |
| -------------------------------------------- | ----------------------- | --------------------------- | -------------- | ----------------- | ------------------ | ----------------------- |
| Timer, dial, presets, images, settings       | ✅                      | ✅                          | ✅             | ✅                | ✅                 | ✅                      |
| Alarm with the app closed (FR-011/012/015)   | ✅ (◐ no exact alarm)   | ✅ (◐ silent mode < iOS 26) | ✅             | ✅ or ◐ per spike | ◐ keep window open | ◐ keep window open      |
| Screen always on (FR-014)                    | ✅                      | ✅                          | ✅             | ✅                | ◐                  | ◐ tab must be visible   |
| Full screen in child mode (FR-030)           | ✅                      | ◐ status bar hidden only    | ✅             | ✅                | ✅                 | ◐ after the Start tap   |
| Unlock with Esc (FR-031)                     | ◐ with a keyboard       | ◐ with a keyboard           | ✅             | ✅                | ✅                 | ✅                      |
| Vibration (FR-054)                           | ✅ if the device has it | ✅ iPhone                   | ✕              | ✕                 | ✕                  | ✕                       |
| Own image from the device (FR-021)           | ✅                      | ✅                          | ✅             | ✅                | ✅                 | ◐ stored in the browser |
| System volume notice                         | ✅                      | ✅                          | ✕              | ✕                 | ✕                  | ✕                       |
| Screen pinning and battery help (FR-018/033) | ✅                      | ✕                           | ✕              | ✕                 | ✕                  | ✕                       |
| Routine step alarms when closed (FR-073)     | ✅                      | ✅                          | ✅             | per spike         | ◐ keep window open | ◐ keep window open      |
| Home screen widget (FR-090, v1.x)            | ✅                      | ✅                          | ✕              | ✕                 | ✕                  | ✕                       |
| System alarm in silent mode (FR-091, v1.x)   | ✕                       | ✅ iOS 26+                  | ✕              | ✕                 | ✕                  | ✕                       |
| Export/import (FR-100, v1.x)                 | ✅ share sheet          | ✅ share sheet              | ✅ save dialog | ✅ save dialog    | ✅ save dialog     | ✅ download             |
| Extended emoji library (FR-120, v1.x)        | ✅                      | ✅                          | ✅             | ✅                | ✅                 | ✅                      |

### Key Entities _(include if feature involves data)_

- **TimerConfig**: duration, scale, direction, visual source (image or palette), sound, volumes,
  ticking, vibration, show digits, image effect (v1.x), warnings (v1.x).
- **TimerSession**: running timer; state (ready, running, paused, finished, cancelled), start
  instant, expected end instant, paused time, config used, origin (manual, preset, routine).
- **ImageAsset**: library image (id, category, localized names, license, author) or own image
  (id, creation date, framing).
- **EmojiAsset** (v1.x): extended library image (id, group, subgroup, localized names and
  keywords, skin-tone variants, license, source).
- **Preset**: id, name, order, TimerConfig, favorite (widget, v1.x).
- **Routine** (v1.x): id, name, advance mode, ordered list of **RoutineStep** (name, duration,
  visual source).
- **RoutineRun** (v1.x): running routine, current step, completed steps, step session.
- **AppSettings**: theme, language (follows the system), child lock, accessibility announcement
  interval, sound and appearance defaults, onboarding flags and notices seen.
- **ExportBundle** (v1.x): format version, date, presets, routines, own images.

## Success Criteria _(mandatory)_

### Measurable Outcomes

Measurement protocols for SC-001 to SC-005, SC-008 and SC-010 are defined in
[testing-strategy.md §8](./testing-strategy.md).

- **SC-001**: An adult without instructions sets up and starts a 5 min timer within 15 s on
  first use (test with 5 adults, median).
- **SC-002**: The alarm fires within ≤ 1 s with the app open and ≤ 5 s with the app closed or the
  screen locked in 100% of 20 runs per platform with native alarms.
- **SC-003**: In 30 attempts of random touches by a child during the countdown, 0 result in a
  pause, cancellation or leaving the app (both the automated and the manual protocol).
- **SC-004**: The dial animates without perceptible stutter (≥ 99% of frames on time) on a
  reference low-end Android device.
- **SC-005**: An adult picks a device photo, frames it and applies it to the dial within 30 s
  (same participants and conditions as SC-001, median).
- **SC-006**: Starting a preset takes at most 2 taps from the home screen.
- **SC-007**: 100% of screens pass a WCAG 2.2 AA accessibility audit (contrast, labels, focus,
  target size) and the platforms' accessibility scanners.
- **SC-008**: 0 network requests at runtime, verified by traffic inspection on all platforms at
  every release.
- **SC-009**: The app opens and shows a usable home screen within 2 s on the reference device.
- **SC-010**: In a test with 3 families, teachers or therapists over 1 week, at least 2 of 3
  report they would use the app instead of their current solution.
- **SC-011** (v1.x): A 5-step routine is created within 2 min by an adult on first use.
- **SC-012** (v1.x): Exporting and importing 20 presets with images between two devices takes
  less than 1 min and preserves 100% of the data.
- **SC-013** (v1.x): An adult finds and applies a named emoji (e.g., "giraffe") from the
  extended library within 20 s, by browsing or by search, on first use.

## Assumptions

- The adult installs and configures the app; the child has no account or profile.
- There is no cloud sync and no accounts; transfer between devices only by file (v1.x).
- Background accuracy depends on each system's policies; vendors with aggressive optimization
  may require manual adjustment by the user, documented in the app.
- The image library comes from collections with compatible licenses (CC0, CC BY 4.0, MIT or
  Apache-2.0); the final selection is reviewed by a human.
- Sounds come from CC0 libraries or are produced by the project, under 30 s.
- On the Web, own images live in the browser's storage and may be erased if the user clears the
  site data; the app says so in the picker.
- Distribution: Google Play, App Store, F-Droid, Web (GitHub Pages), Flathub and GitHub
  Releases; publishing to stores is a release activity, outside this functional specification.
- The system "reduce transparency" setting (iOS/macOS/Windows) is not read directly (Flutter
  does not expose it); the app uses no blur or vibrancy, and its only translucency (the elapsed
  sector) becomes opaque when the system's increase-contrast setting is on.
- Out of scope up to v1.x: watches (Wear OS, Apple Watch), classroom mode with several
  simultaneous timers, recorded narration, reward board, per-child profiles, sync.
