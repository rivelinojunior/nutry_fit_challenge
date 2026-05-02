# Repository Guidelines

## Project Structure & Module Organization

This is a Rails 8 application for a Nutry.fit challenge MVP. Core application code lives in `app/`: models in `app/models`, controllers in `app/controllers`, views in `app/views`, jobs in `app/jobs`, and frontend behavior in `app/javascript/controllers`. Styles and build outputs are under `app/assets`, including Tailwind assets. Database migrations and schemas live in `db/`; keep `db/schema.rb` updated with migrations. Tests live in `spec/`, with factories in `spec/factories` and shared helpers in `spec/support`.

Business rules should be kept out of controllers. Follow the README architecture: put workflow/domain logic in `app/processes` when adding non-trivial behavior, with explicit input, injectable dependencies, and structured results.

## Build, Test, and Development Commands

- `bundle install`: install Ruby dependencies.
- `cp .env.sample .env`: create local environment configuration.
- `docker compose up -d postgres`: start the local PostgreSQL service on port `5437`.
- `bin/rails db:prepare`: create, migrate, and prepare local databases.
- `bin/dev`: run Rails and Tailwind watchers via `Procfile.dev`.
- `bundle exec rspec`: run the test suite.
- `bin/rubocop`: check Ruby style using Rails Omakase rules.
- `bin/ci`: run local setup, RuboCop, bundler-audit, importmap audit, and Brakeman.

## Coding Style & Naming Conventions

Use standard Rails naming: singular models (`User`), plural controllers, snake_case files, and descriptive migration names. Follow RuboCop Rails Omakase; do not introduce local style exceptions unless they remove real friction. Prefer small controllers, explicit model validations, and service/process objects for multi-step business workflows. Keep locale strings in `config/locales`.

## Testing Guidelines

RSpec and FactoryBot are the test stack. Name specs `*_spec.rb` and mirror the application path, for example `spec/models/user_spec.rb` for `app/models/user.rb`. Add focused examples for validations, associations, process results, and controller/request behavior when those layers change. Run `bundle exec rspec` before opening a PR; run `bin/ci` when touching security-sensitive, dependency, or style-related code.

## Commit & Pull Request Guidelines

Recent commits use short, imperative summaries such as `Add Devise user authentication` and `Set up RSpec and FactoryBot`. Keep commits scoped to one concern and include migrations/schema changes with model changes. Pull requests should describe the behavior change, list verification commands, link related issues when available, and include screenshots for UI changes.

## Security & Configuration Tips

Do not commit `.env`, credentials, logs, or local database files. Use `.env.sample` for documented configuration keys. Authentication uses Devise; avoid logging secrets or personal data, and keep `config/initializers/filter_parameter_logging.rb` updated when adding sensitive parameters.
