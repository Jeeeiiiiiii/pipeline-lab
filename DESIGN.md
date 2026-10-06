---
name: pipeline-lab Operating Theatre
description: The CI/CD pipeline run as a WHO-style surgical checklist, each stage ticked GO or NO-GO from its own exit code, beside the deployed app as the patient on a black bedside monitor.
colors:
  wall: "#D7E2DC"
  wall-deep: "#C3D2CA"
  wall-ink: "#1B2A25"
  wall-dim: "#47594F"
  sheet: "#FBFCF9"
  sheet-rule: "#CBD6CF"
  sheet-hover: "#EEF2EE"
  tail-wash: "#F1F4F1"
  ink: "#17221F"
  ink-dim: "#4D5C55"
  idle-box: "#7F8E87"
  go: "#1E6E50"
  go-wash: "#E2F0E8"
  scrub: "#2A5F9E"
  scrub-deep: "#224F86"
  bezel: "#101614"
  screen: "#050807"
  grid: "#13261C"
  phosphor: "#4FE08C"
  phosphor-dim: "#45A872"
  screen-text: "#CFE9DA"
  screen-note: "#B8CDC1"
  no-signal: "#7C8C84"
  control-dark: "#1B2420"
  control-dark-hover: "#24302A"
  control-dark-rule: "#2C3B34"
  warn: "#F4C542"
  on-warn: "#231A00"
  alarm: "#F0504F"
typography:
  display:
    fontFamily: "Atkinson Hyperlegible Next, Segoe UI, system-ui, sans-serif"
    fontSize: "2.3rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "-0.01em"
  headline:
    fontFamily: "Atkinson Hyperlegible Next, Segoe UI, system-ui, sans-serif"
    fontSize: "1.2rem"
    fontWeight: 800
    lineHeight: 1.2
  title:
    fontFamily: "Atkinson Hyperlegible Next, Segoe UI, system-ui, sans-serif"
    fontSize: "0.82rem"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "0.12em"
  body:
    fontFamily: "Atkinson Hyperlegible Next, Segoe UI, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    fontFeature: "tnum"
  label:
    fontFamily: "Atkinson Hyperlegible Next, Segoe UI, system-ui, sans-serif"
    fontSize: "0.72rem"
    fontWeight: 700
    letterSpacing: "0.1em"
  readout:
    fontFamily: "Atkinson Hyperlegible Mono, ui-monospace, Consolas, monospace"
    fontSize: "2.1rem"
    fontWeight: 700
    lineHeight: 1.1
  screen-label:
    fontFamily: "Atkinson Hyperlegible Mono, ui-monospace, Consolas, monospace"
    fontSize: "0.74rem"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.1em"
  data:
    fontFamily: "Atkinson Hyperlegible Mono, ui-monospace, Consolas, monospace"
    fontSize: "0.8rem"
    fontWeight: 700
    lineHeight: 1
  trace-label:
    fontFamily: "Atkinson Hyperlegible Mono, ui-monospace, Consolas, monospace"
    fontSize: "11px"
    fontWeight: 400
rounded:
  tag: "2px"
  box: "3px"
  sheet: "4px"
  screen: "6px"
  bezel: "14px"
spacing:
  chip-gap: "6px"
  control-gap: "10px"
  slot: "5px 12px 6px"
  line: "10px 0 11px"
  monitor: "14px"
  theatre-gap: "22px"
  sheet: "18px 22px 22px"
  page: "22px 28px 44px"
components:
  button-primary:
    backgroundColor: "{colors.scrub}"
    textColor: "#FFFFFF"
    typography: "{typography.body}"
    rounded: "{rounded.sheet}"
    padding: "10px 16px"
  button-primary-hover:
    backgroundColor: "{colors.scrub-deep}"
  button-secondary:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.sheet}"
    padding: "10px 16px"
  button-secondary-hover:
    backgroundColor: "{colors.sheet-hover}"
  button-monitor:
    backgroundColor: "{colors.control-dark}"
    textColor: "{colors.screen-text}"
    rounded: "{rounded.sheet}"
    padding: "10px 16px"
  button-monitor-hover:
    backgroundColor: "{colors.control-dark-hover}"
  button-monitor-harm:
    backgroundColor: "{colors.control-dark}"
    textColor: "#FFFFFF"
    rounded: "{rounded.sheet}"
    padding: "10px 16px"
  checklist-sheet:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.sheet}"
    padding: "{spacing.sheet}"
  tick-box-idle:
    backgroundColor: "{colors.sheet}"
    rounded: "{rounded.box}"
    size: "22px"
  tick-box-go:
    backgroundColor: "{colors.go-wash}"
    rounded: "{rounded.box}"
    size: "22px"
  tick-box-nogo:
    backgroundColor: "{colors.ink}"
    rounded: "{rounded.box}"
    size: "22px"
  status-go:
    textColor: "{colors.go}"
    typography: "{typography.data}"
  status-nogo:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.sheet}"
    typography: "{typography.data}"
    rounded: "{rounded.tag}"
    padding: "1px 7px"
  chip:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.ink}"
    typography: "{typography.data}"
    rounded: "{rounded.tag}"
    padding: "4px 6px 3px"
  chip-critical:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.sheet}"
    typography: "{typography.data}"
    rounded: "{rounded.tag}"
    padding: "4px 6px 3px"
  board-slot:
    backgroundColor: "{colors.sheet}"
    textColor: "{colors.ink}"
    padding: "{spacing.slot}"
  board-slot-pending:
    backgroundColor: "{colors.warn}"
    textColor: "{colors.on-warn}"
  board-slot-firing:
    backgroundColor: "{colors.alarm}"
    textColor: "#FFFFFF"
  monitor:
    backgroundColor: "{colors.bezel}"
    textColor: "{colors.screen-text}"
    rounded: "{rounded.bezel}"
    padding: "{spacing.monitor}"
  monitor-screen:
    backgroundColor: "{colors.screen}"
    rounded: "{rounded.screen}"
    padding: "12px 14px 14px"
  readout-value:
    textColor: "{colors.phosphor}"
    typography: "{typography.readout}"
  alarm-bar-pending:
    backgroundColor: "{colors.warn}"
    textColor: "{colors.on-warn}"
    rounded: "{rounded.sheet}"
    padding: "7px 10px"
  alarm-bar-firing:
    backgroundColor: "{colors.alarm}"
    textColor: "#FFFFFF"
    rounded: "{rounded.sheet}"
    padding: "7px 10px"
---

# Design System: pipeline-lab Operating Theatre

## Overview

**Creative North Star: "The Operating Theatre"**

A deployment is an operation. The page is a theatre wall in clinical green-grey with two objects on it: a printed WHO-style surgical checklist and a black bedside monitor. The checklist runs in three phases (sign in, procedure, sign out); every line is one stage script, and its tick box is signed by that script's own exit code, with the scanner's evidence written underneath. The monitor shows the deployed app as the patient: one phosphor trace of its error rate, numeric readouts, and the alert. Above both hangs the theatre board, a ruled grid of labelled slots saying what is on the table.

The register is calm, legible and procedural. Density is moderate: a checklist line carries a name, a stage id, one sentence of purpose, a status and a duration, and the evidence chips only when a scan wrote them. Colour is spent sparingly and by role: green-grey for the room, near-black ink for the paperwork, scrub-blue for the operator's hand, phosphor green for the instrument, and yellow and red held back for the alert alone. A refusal at a gate is the system working, so it is printed in reversed ink, never in alarm colours.

This world is its own and is distinct from the sibling labs: not finops-agent's engine-room logbook, not rag-lab's wire desk, not order-lab's split-flap departures board, and not mesh-lab's grey-blue bench instrument. It shares only the house habits of those pages (one static file, self-hosted type, state read live from the running lab).

**Key Characteristics:**
- Clinical green-grey wall, an off-white printed sheet, and a flat black monitor: three materials, each with its own palette.
- GO is a green tick; NO-GO is ink-reversed (black box, white cross, inverted tag). Neither uses the alarm colours.
- Yellow (WARNING, pending) and red (ALARM, firing) appear only in the alert: the monitor readout, the alarm bar, and the board's alert slot.
- Scrub-blue marks the one primary action and the operator's focus, nothing else on the wall.
- One family, two cuts: Atkinson Hyperlegible Next for everything a person reads as prose, Atkinson Hyperlegible Mono for data.
- Flat modern monitor: no glow, no scanlines, no CRT curvature.

## Colors

A cool, low-chroma clinical palette with three saturated hues held in reserve for meaning: green for a ticked line, scrub-blue for the operator, and yellow and red for the alert.

### Primary
- **Scrub Blue** (#2A5F9E): the one primary action ("Start full procedure"), the focus ring (2px outline, 3px offset), text selection, and the "in progress" status word on a running line. Deepens to **Scrub Deep** (#224F86) on hover.

### Secondary
- **Theatre Green Tick** (#1E6E50): the GO tick stroke, the GO status word, the GO box border, and the border of a completed verdict. Paired with **Tick Wash** (#E2F0E8) inside a ticked box and behind a completed verdict.

### Tertiary
- **Monitor Phosphor** (#4FE08C): the trace line, the readout numerals and the patient name on the screen. **Phosphor Dim** (#45A872, about 6:1 on the screen) carries every label on the screen: trace axis labels, readout labels, the screen header.
- **Warning Yellow** (#F4C542): WARNING, the alert pending. Fills the alarm bar and the board's alert slot (with **On-warn** #231A00 text), colours the WARNING readout, and draws the dashed 5% threshold line and its label on the trace, because that line is where the warning begins.
- **Alarm Red** (#F0504F): ALARM, the alert firing. Fills the alarm bar and the board's alert slot (white text) and colours the ALARM readout. Nowhere else.

### Neutral
- **Theatre Wall** (#D7E2DC): the page background. **Wall Deep** (#C3D2CA) rules the colophon.
- **Wall Ink** (#1B2A25): headings and text set directly on the wall; the 2px rule under the board and the board's 1.5px frame. **Wall Dim** (#47594F): lede and colophon prose on the wall.
- **Checklist Paper** (#FBFCF9): the checklist sheet, the board slots, secondary buttons and chips. **Sheet Rule** (#CBD6CF): the rules between checklist lines, between board slots, and chip borders. **Sheet Hover** (#EEF2EE): secondary button hover. **Tail Wash** (#F1F4F1): the stage's last-five-lines output tail.
- **Checklist Ink** (#17221F): text on the sheet, the 2px rule opening each phase, the NO-GO box fill, the NO-GO tag and the CRITICAL/ERROR chip. **Ink Dim** (#4D5C55): stage purpose lines, phase titles, durations, idle lines.
- **Idle Box** (#7F8E87, about 3.3:1 on the sheet): the border of a tick box that has not run yet; the resting box must stay visible.
- **Bezel** (#101614) and **Screen** (#050807): the monitor's case and its glass. **Grid** (#13261C): trace gridlines. **Screen Text** (#CFE9DA): readout explanations and treatment results. **Screen Note** (#B8CDC1): the sans explanatory note under the monitor. **No Signal** (#7C8C84): the alert readout when the cluster cannot be read.
- **Control Dark** (#1B2420, hover #24302A, border #2C3B34): the treatment buttons on the monitor.

### Named Rules
**The Reserved Alarm Rule.** Yellow (#F4C542) and red (#F0504F) belong only to the alert: WARNING means pending, ALARM means firing, and they appear in the monitor readout, the alarm bar, the board's alert slot and the threshold line. No button, stage, finding or decoration may borrow them.

**The Gate Works Rule.** A NO-GO is the gate doing its job. It is ink-reversed (black box with a white cross, inverted "NO-GO" tag in mono), never red. A CRITICAL or ERROR finding chip is reversed the same way.

**The One Scrub Rule.** Scrub-blue is the operator's hand: one primary action per surface, plus focus, selection and the live "in progress" word. Harm is marked by weight, not hue.

## Typography

**Body Font:** Atkinson Hyperlegible Next, variable 200-800, self-hosted (with Segoe UI, system-ui)
**Label/Mono Font:** Atkinson Hyperlegible Mono, variable 200-800, self-hosted (with ui-monospace, Consolas)

**Character:** One hyperlegible family in two cuts. The sans does the talking, heavy (800) for headings and stage names, regular for prose; the mono is the instrument's and the form's printed data. Tabular figures are on for the whole page so durations and readouts never jitter.

### Hierarchy
- **Display** (800, 2.3rem, 1.9rem on phones, line-height 1, -0.01em): the theatre name on the board ("Theatre 1"), with the project name after it at 400 in Wall Dim.
- **Headline** (800, 1.2rem, 1.2): the sheet title ("Surgical checklist").
- **Title** (800, 0.82rem, 0.12em, uppercase, Ink Dim): phase headings (Sign in, Procedure, Sign out), with a sentence-case regular subtitle at 0.9rem aligned right.
- **Body** (400, 16px, 1.5): lede, notes, stage purpose lines (0.95rem, max 62ch), verdicts; lede measure 78ch, sheet note 70ch. Stage names are body at 800.
- **Label** (700, 0.72rem, 0.1em, uppercase, Ink Dim): the board slot labels (On the table, Last tag prepared, Pushed, ECR repository, Cluster, AppHighErrorRate). Slot values are body at 700.
- **Readout** (mono 700, 2.1rem, 1.1, Phosphor): monitor numerals; the unit follows at 0.9rem regular in Phosphor Dim. The alert word (NORMAL, WARNING, ALARM, NO SIGNAL) is 1.35rem with 0.04em tracking.
- **Screen Label** (mono 600, 0.74rem, 0.1em, uppercase, Phosphor Dim): readout labels; the screen header is the same at 0.8rem / 0.08em.
- **Data** (mono 700, 0.8rem): chips (stage id, severity counts), GO/NO-GO tags (0.92rem), durations and exit codes, severity column in evidence lists, the output tail (400, 0.8rem/1.45).
- **Trace Label** (mono 400, 11px, Phosphor Dim): trace axis labels, kept at 11px on every screen width.

### Named Rules
**The Data-Only Mono Rule.** On the wall and the sheet, mono is only for data: GO / NO-GO, exit codes, durations, tags, stage ids, severities, image names, command lines. Status prose ("waiting", "not started", "after a NO-GO") and every explanation are the sans. The monitor screen is the instrument and prints in mono throughout; the explanatory note beneath it is sans.

**The Same Size Everywhere Rule.** The trace's SVG viewBox is set to the element's own pixel width, so 11px axis labels render at 11px on a phone as on a desktop. Never scale chart text with the viewport.

## Layout

A centred page (max 1400px, padding 22px 28px 44px; 18px 16px 34px on phones). The board heads the page: the display name and a ruled grid of six labelled slots, separated from the theatre by a 2px Wall Ink rule. Below a one-paragraph lede, the theatre is a two-column grid (checklist 1.15fr, monitor 1fr, gap 22px); the monitor is sticky (top 14px) so the patient stays in view while the checklist scrolls.

Responsive behaviour is fixed and deliberate:
- **Above 1640px:** the board's six slots sit in one row beside the name.
- **1640px and below:** the slots stretch to a 3 x 2 grid under the name.
- **1100px and below:** the theatre stacks, checklist first; the monitor stops being sticky.
- **720px and below:** the slots become two columns with the alert slot first and full width, and the Cluster slot spanning the last row so no cell is empty; a tag never breaks inside itself. Checklist lines drop to box + text with the status under the text. Readouts become two columns with the alert readout full width. The screen header drops the namespace.

Spacing rhythm is small and tight: 6px between chips, 10px between controls, lines padded 10px / 11px, the sheet padded 18px 22px 22px (16px 14px 18px on phones), the monitor 14px. A checklist line is a three-column grid (30px box, text, right-aligned status) with evidence and output tail spanning the text and status columns.

## Elevation & Depth

Mostly flat, with two physical objects. The checklist sheet lies on the wall with a hairline and a soft drop; the monitor stands off the wall with a deeper, darker drop. Everything else (board, slots, lines, chips, buttons) is flat and separated by rules. The screen sits inside the bezel by a 1px inset edge, not a glow.

### Shadow Vocabulary
- **Sheet on the wall** (`box-shadow: 0 1px 0 rgba(0,0,0,.08), 0 12px 26px -16px rgba(16,30,24,.45)`): the checklist paper only.
- **Monitor off the wall** (`box-shadow: 0 18px 30px -18px rgba(5,12,9,.8)`): the bedside monitor only.
- **Screen glass edge** (`box-shadow: inset 0 0 0 1px #0E1C15`): the screen inside the bezel.

### Named Rules
**The Flat Monitor Rule.** The screen is a flat modern patient monitor. No glow, bloom, text-shadow, scanlines or curvature on the trace, the numerals or the alarm.

## Shapes

Small, practical corners graded by object size: 2px on tags and chips, 3px on tick boxes, the board frame and the output tail, 4px on the sheet, buttons, verdict, banner and alarm bar, 6px on the screen and 14px on the monitor bezel, the only soft object in the room. Structure comes from rules: a 2px ink rule opens every phase and closes the board, 1px Sheet Rule lines divide checklist lines and board slots. The tick box is a 22px square with a 2px border; its states are drawn as inline SVG strokes (tick, cross), dashed border while running.

## Components

### Buttons
Plain, firm and labelled with what they do.
- **Shape:** gently squared (4px), 1px border, padding 10px 16px, weight 700.
- **Primary:** Scrub Blue fill and border, white text; hover Scrub Deep. One per surface ("Start full procedure").
- **Secondary:** Checklist Paper fill, 1px Checklist Ink border; hover Sheet Hover.
- **Monitor treatment buttons:** Control Dark fill, Control Dark Rule border, Screen Text label; hover Control Dark Hover.
- **Harmful action ("Induce failure"):** the same dark button with a Screen Text border, white label at 800. Marked by weight, never by hue.
- **Hover / Focus / Press:** background change over 0.12s; press scales to 0.97 over 0.14s on cubic-bezier(.16, 1, .3, 1); focus is the 2px Scrub Blue outline at 3px offset. Disabled is 50% opacity and not-allowed. This is the only authored motion in the system.

### Chips
- **Style:** mono 700 at 0.8rem, 2px corners, padding 4px 6px 3px, 1px Sheet Rule border on paper. Used for the stage id beside each stage name and for scanner severity counts.
- **State:** HIGH gets a Checklist Ink border; CRITICAL and ERROR are reversed (ink fill, paper text). Severity never takes the alarm colours.

### Cards / Containers
- **Checklist sheet:** Checklist Paper, 4px corners, Sheet on the wall shadow, padding 18px 22px 22px.
- **Verdict:** 2px Checklist Ink border, 4px corners, padding 12px 14px; a completed procedure turns the border Theatre Green Tick on Tick Wash. A stopped procedure keeps the ink border: stopped at a gate is reported plainly.
- **Output tail:** mono 0.8rem/1.45 on Tail Wash, 3px corners, last five lines, capped at 7.4em, shown only while a stage runs or after a NO-GO.
- **Fault banner:** a pale brick notice (fill #F6E3DF, border #B55A4E, text #6E2219, 4px) used only when the theatre server stops answering or the cluster cannot be read, carrying the recovery command in mono.

### Theatre Board (signature)
A ruled grid of labelled slots on Checklist Paper inside a 1.5px Wall Ink frame (3px corners): On the table, Last tag prepared, Pushed, ECR repository, Cluster, AppHighErrorRate. Label above value; tags and repository names in mono. The alert slot carries the alert word in mono and is filled Warning Yellow when pending and Alarm Red when firing; at rest it is plain paper. Six across above 1640px, 3 x 2 below, two columns on phones with the alert slot first and full width.

### Checklist Line (signature)
Tick box, stage name (sans 800) with its stage-id chip, one sentence of purpose, and a right-aligned status. States:
- **Idle:** Idle Box border, text in Ink Dim, status "waiting".
- **Running:** dashed ink border, "in progress" in Scrub Blue mono, live elapsed time, output tail below.
- **GO:** green border on Tick Wash with a green SVG tick; "GO" in green mono 700, duration beneath.
- **NO-GO:** ink-filled box with a paper-coloured SVG cross; "NO-GO" as an inverted ink tag (0.06em tracking), "exit N · duration" beneath, output tail below.
- **Not started / not in this run:** sans status with a small reason ("after a NO-GO", "sign-in only").
Scanner evidence sits under the line: severity chips, the deciding rule in Ink Dim, and a two-column list (mono severity, finding with its location).

### Bedside Monitor (signature)
- **Case:** Bezel, 14px corners, padding 14px, Monitor off the wall shadow; screen inside at 6px with a 1px inset edge.
- **Header:** screen-label mono, "Patient: app" with the patient name in Phosphor, the live tag at the right.
- **Trace:** plots exactly the PrometheusRule expression, 5xx over all `flask_http_request_total`, as a 1-minute rate, over the last ten minutes. 2px Phosphor stroke, round joins; Grid gridlines at five levels and every two minutes; a dashed (4 4) Warning Yellow line at 5% labelled "5% threshold". The y-axis is capped at 100%. Windows with no traffic are gaps: each run of samples is its own polyline (a lone sample is a 2px dot), never interpolated across.
- **Readouts:** three columns (Errors 1 m, Requests, AppHighErrorRate) above a 1px rule; numerals in Readout type. The alert readout shows NORMAL in Phosphor, WARNING in Warning Yellow, ALARM in Alarm Red, NO SIGNAL in No Signal grey, with a one-line mono reason beneath.
- **Alarm bar:** hidden at rest; mono 700 0.9rem, filled Warning Yellow (pending) or Alarm Red (firing), stating the alert and its rule in words. It carries no percentage: the Errors readout is the one error figure on the screen.
- **Treatments:** the dark treatment buttons below the screen, a mono result line, and a sans note explaining the expression.
The WARNING (pending) appearance of the readout, bar and slot is coded but has not yet been seen in a capture; verify it before building on it.

## Do's and Don'ts

### Do:
- **Do** sign every checklist line from the stage's own exit code and show the scanner's evidence under it.
- **Do** print a NO-GO ink-reversed: Checklist Ink (#17221F) box with a paper cross and an inverted mono "NO-GO" tag.
- **Do** keep Warning Yellow (#F4C542) and Alarm Red (#F0504F) for the alert's pending and firing states only.
- **Do** use Scrub Blue (#2A5F9E) for one primary action per surface, and for focus and selection.
- **Do** mark a harmful control by weight (800, brighter border), not by colour.
- **Do** use Atkinson Hyperlegible Mono only for data on the wall and sheet; keep status prose in Atkinson Hyperlegible Next.
- **Do** plot the alert's own expression on the trace, leave no-traffic windows as gaps, cap the axis at 100%, and size the SVG viewBox to the element's pixel width.
- **Do** keep exactly one error figure on screen, the Errors readout.
- **Do** keep the idle tick box border at #7F8E87 or darker so an unrun line is still visible.

### Don't:
- **Don't** colour a NO-GO, a CRITICAL finding, a stopped verdict or a harmful button red or yellow.
- **Don't** add glow, bloom, text-shadow or scanlines to the monitor; it is a flat modern screen.
- **Don't** interpolate the trace across windows with no traffic, or let the y-axis pass 100%.
- **Don't** repeat the error percentage in the alarm bar or anywhere else on the screen.
- **Don't** set status prose or explanations in mono on the wall or the sheet.
- **Don't** add a second Scrub Blue action beside the primary one.
- **Don't** add motion beyond hover and press feedback without recording it here first.
