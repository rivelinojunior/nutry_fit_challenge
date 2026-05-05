# DESIGN.md

AI instructions for building UI in this Rails app.

## Product

Build for **Desafio Nutry.fit**: a Rails 8 + Hotwire + DaisyUI challenge app where admins create point-based daily challenges and participants join, check in, earn points, and view rankings.

Tone: practical, friendly, community-oriented. Reward consistency, not perfection. Avoid guilt, medical-dashboard language, or intense fitness-performance styling.

## Stack

- Rails views: `app/views`
- Hotwire behavior: `app/javascript/controllers`
- Styling: Tailwind + DaisyUI in `app/assets`
- Auth: Devise session auth
- Business workflows: `app/processes`

Do not introduce React, TSX, Next.js, shadcn, API-token patterns, or frontend-only architecture.

## Visual Rules

- Use a clean white/gray interface with bright green as the main brand signal.
- Primary green: `#1EBA09`; Tailwind/DaisyUI primary token: `oklch(0.65 0.22 145)`.
- CTA gradient, only for high-commitment actions: `linear-gradient(to right, #00A6FB, #1DB309)`.
- Use white public pages; use `gray-50` for authenticated app pages.
- Use white cards for tasks, points summaries, ranking rows, and dialogs.
- Base radius: `0.625rem`; use `rounded-md` for controls, `rounded-lg`/`rounded-xl` for cards, `rounded-full` for primary entry/check-in CTAs.
- Light shadows are allowed for compact cards and major CTAs. Do not stack multiple shadowed containers.
- Use Poppins if adding or configuring fonts. Otherwise preserve the existing project font setup.

## Layout Rules

- Mobile-first.
- Keep participant screens simple: today’s tasks, points, ranking, and challenge status.
- Use constrained content widths for daily-use screens, around `max-w-3xl`.
- Prefer clear rows, compact cards, and simple separators over dense dashboards.
- Do not wrap whole pages in decorative cards.
- Admin screens may be more structured, but participant flows must stay direct.

## Component Rules

- Primary buttons: green or CTA gradient.
- Secondary buttons: muted, outline, or ghost DaisyUI styles.
- Destructive actions: require confirmation and use destructive/error styling.
- Forms: visible labels, inline errors, rounded inputs, clear submit state.
- Check-ins: completed tasks must show a green check/completed state without disappearing.
- Rankings: bold rank/points, stable alignment, minimal decoration.
- Dialogs: use only for confirmation, destructive actions, task details, or publish warnings.
- Loading states: plain spinner/loading indicator plus short text.

## Motion

Use motion only for feedback:

- async button/loading states
- short hover/opacity transitions
- simple `200ms` day/tab transitions
- simple `300ms` panel transitions

Do not add decorative, bouncy, or layout-heavy animation.

## Copy Rules

- Portuguese copy should be short, warm, and direct.
- Prefer action labels like `Entrar no desafio`, `Marcar tarefa`, `Ver ranking`, `Publicar desafio`.
- Use points and consistency language. Avoid calorie, nutrition-plan, meal, recipe, grocery, or medical language unless a feature explicitly adds it.

## Product Flows

Design around these flows only:

1. Devise sign-up/sign-in.
2. Admin creates and publishes a challenge.
3. Admin defines daily pointable tasks.
4. System materializes `ChallengeTask` records by day.
5. Participant joins before challenge start.
6. Participant checks in daily tasks.
7. Participant sees points and per-challenge ranking.

## Do Not Do

- No React/TSX/Next references.
- No meal-plan, groceries, recipe, nutrition KPI, or AI-plan UI.
- No token storage in browser JavaScript.
- No dark analytics-dashboard look.
- No full-page gradients.
- No card mosaics as the default layout.
- No guilt-based fitness copy.
