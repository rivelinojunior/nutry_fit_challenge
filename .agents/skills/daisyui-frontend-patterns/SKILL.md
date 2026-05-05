---
name: daisyui-frontend-patterns
description: Build or refine Rails UI for the Desafio Nutry.fit app using ERB, Hotwire, Tailwind, and DaisyUI while following DESIGN.md. Use when creating or changing Rails views, layouts, partials, forms, buttons, cards, dialogs, flash messages, navigation, Stimulus controllers, Turbo interactions, participant check-in screens, rankings, or admin challenge setup screens. Do not use for React, TSX, Next.js, shadcn, meal-plan, grocery, recipe, nutrition KPI, or frontend-only architecture work.
---

# DaisyUI Frontend Patterns

Use this skill to implement Rails UI that matches this project's compact design rules.

## Required Context

Before editing UI:

1. Read `DESIGN.md`.
2. Inspect nearby Rails views/partials and existing Tailwind/DaisyUI patterns.
3. If using DaisyUI, Tailwind, Turbo, or Stimulus APIs you are not certain about, resolve and query the current docs with Context7 before coding.

## Stack Boundaries

Use only this stack for UI work:

- Rails ERB views and partials in `app/views`
- Hotwire/Turbo for server-driven updates
- Stimulus controllers in `app/javascript/controllers` for progressive enhancement
- Tailwind + DaisyUI classes from `app/assets`
- Devise session-authenticated flows

Do not introduce React, TSX, Next.js, shadcn, browser token storage, or separate frontend architecture.

## Workflow

1. Identify the user flow: admin challenge setup, participant join, daily check-in, points summary, ranking, or auth.
2. Keep controllers thin. Put non-trivial workflow behavior in `app/processes` and render simple view state.
3. Build mobile-first ERB with constrained content width, usually `max-w-3xl mx-auto px-4` for participant screens.
4. Prefer DaisyUI semantic classes plus project-specific Tailwind utilities over raw custom CSS.
5. Add Turbo Frames/Streams only for discrete server-updated regions. Use Stimulus only for local UI behavior.
6. Check states before finishing: empty, loading, success, error, disabled, hover/focus, and mobile wrapping.

## Visual Rules

Follow `DESIGN.md` exactly:

- Clean white/gray UI with bright green as the main brand signal.
- Primary green: `#1EBA09`; primary token: `oklch(0.65 0.22 145)`.
- CTA gradient only for high-commitment actions: `linear-gradient(to right, #00A6FB, #1DB309)`.
- White public pages; `gray-50` authenticated app pages.
- White compact cards for tasks, points summaries, rankings, participant status, and dialogs.
- Base radius `0.625rem`; `rounded-md` controls, `rounded-lg`/`rounded-xl` cards, `rounded-full` entry/check-in CTAs.
- Light shadows only for compact cards and major CTAs.
- No full-page gradients, dark analytics dashboards, decorative card mosaics, or guilt-based fitness styling.

## DaisyUI Patterns

Use these mappings unless existing app code establishes a better local pattern:

- Primary action: `btn btn-primary`
- Secondary action: `btn btn-outline`, `btn btn-ghost`, or muted button styling
- Destructive action: `btn btn-error` plus confirmation
- Card: `card bg-base-100 shadow-sm border border-base-300`
- Alert/flash: `alert`, with `alert-success`, `alert-warning`, or `alert-error`
- Badge/status: `badge`, with `badge-success`, `badge-warning`, `badge-error`, or `badge-outline`
- Text input: `input input-bordered w-full`
- Select: `select select-bordered w-full`
- Textarea: `textarea textarea-bordered w-full`
- Checkbox: `checkbox checkbox-primary`
- Loading: `loading loading-spinner loading-sm` inside the affected button or region

Keep class lists readable. Do not replace every layout decision with a custom component or raw CSS.

## Challenge UI Patterns

Participant screens:

- Put today's tasks first.
- Show points and completion status near the top.
- Checked-in tasks remain visible and switch to a green completed state.
- Ranking rows should make rank, participant name, and points scannable.
- Use short Portuguese labels: `Entrar no desafio`, `Marcar tarefa`, `Ver ranking`.

Admin screens:

- Make challenge status obvious: draft, published, started, finished.
- Keep task definition forms structured but not dashboard-heavy.
- Use warning/confirmation UI before publishing, removing tasks, or making destructive changes.
- Keep generated/materialized task results readable by date.

## Hotwire Rules

Use Turbo when the server owns the state:

- wrap check-in lists, ranking tables, or task lists in stable `turbo_frame_tag` IDs when partial replacement is useful
- use Turbo Streams for updating check-in state, points summary, flash, and ranking snippets after mutations
- keep Turbo target IDs domain-specific, e.g. `today_tasks`, `points_summary`, `challenge_ranking`

Use Stimulus only for client-side behavior such as toggles, lightweight filtering, confirmation affordances, or temporary UI state. Keep one controller per behavior.

## Copy Rules

Write in concise Brazilian Portuguese by default. Use points, consistency, and community language. Avoid calorie, meal, recipe, grocery, medical, or nutrition-plan language unless the product scope explicitly changes.

## Final Check

Before finishing UI work, verify:

- `DESIGN.md` rules are followed.
- The page still fits Rails + Hotwire + DaisyUI.
- The primary action is obvious on mobile.
- Forms have labels and error states.
- Destructive actions require confirmation.
- Loading and empty states are not missing.
- No out-of-scope React/TSX/Next or meal-plan/nutrition UI was introduced.
