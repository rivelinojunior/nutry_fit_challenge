---
name: rspec-review
description: >-
  Reviews RSpec test files for quality and correctness using Better Specs best practices
  and this project's conventions. Use whenever the user asks to review, audit, check,
  or improve RSpec specs — even if they just say "review this test", "check my spec",
  "is this test good?", or "improve this spec". Also trigger when writing new tests,
  when tests are pasted in the conversation, or when the user shares a spec file path.
  WHEN NOT: Writing new specs from scratch (use @solid-process-agent or @controller-agent).
---

# RSpec Review Skill

Your job is to review RSpec specs and report violations with specific line references and actionable fixes. Ground every comment in observable evidence from the code — never invent issues that aren't there.

**Before reviewing, read the implementation file** (the class or module under test). This is essential: you cannot detect coverage gaps by looking at the spec alone. Find the implementation by resolving the spec path — e.g., `spec/processes/foo_process_spec.rb` → `app/processes/foo_process.rb`. Read it to understand every branch, condition, and outcome the code handles, then compare against what the spec exercises.

## BDD Structure

RSpec is a behavior-driven framework. Every spec must follow a strict three-level structure that maps directly to **what** is being tested, **under what condition**, and **what the expected outcome is**:

| Layer | Keyword | Purpose |
|-------|---------|---------|
| Method or feature | `describe` | What is being exercised |
| Condition | `context` | The scenario or state |
| Expected outcome | `it` | The observable result |

**Good:**
```ruby
RSpec.describe PasswordStrengthChecker do
  describe '#strong?' do
    subject(:strong_password?) { described_class.new(password).strong? }

    context 'when the password meets all requirements' do
      let(:password) { 'MySecure123!' }

      it 'returns true' do
        expect(strong_password?).to be true
      end
    end

    context 'when the password is too short' do
      let(:password) { 'Ab1!' }

      it 'returns false' do
        expect(strong_password?).to be false
      end
    end
  end
end
```

**Violations to flag:**
- `it` blocks that express a condition instead of an outcome (e.g., `it 'when user is admin'`)
- `describe` used for conditions instead of `context` (e.g., `describe 'invalid input' do`)
- Flat specs with no `context` grouping where the same method is tested under multiple conditions
- `context` blocks containing only one `it` that could have been written directly under `describe` — only flag if the context adds no meaningful scoping

---

## Review Checklist

Work through each rule below. For each violation found, record: **rule name**, **line(s)**, **what's wrong**, and **how to fix it** with a corrected snippet.

---

### 1. Describe Methods Correctly

`describe` blocks for methods must use Ruby documentation conventions:
- Class methods: `describe '.method_name'`
- Instance methods: `describe '#method_name'`

**Bad:** `describe 'the authenticate method'`, `describe 'POST /endpoint'` inside a model spec
**Good:** `describe '.call'`, `describe '#valid?'`

> For request specs (`type: :request`), describing the HTTP verb and path (`describe 'POST /api/v1/...'`) is acceptable and idiomatic.

---

### 2. Use Contexts to Express Conditions

Group related examples under `context` blocks. Context descriptions must start with **"when"**, **"with"**, or **"without"** to make the condition explicit. Avoid `describe` for condition branches.

**Bad:** `context 'invalid user'`, `describe 'no token present'`
**Good:** `context 'when the user is invalid'`, `context 'without a token'`

---

### 3. Keep It Descriptions Short

`it` descriptions should stay under 70 characters. Long descriptions are a sign the example is testing too many things or the context isn't narrow enough. Move condition details into a surrounding `context`.

**Bad:** `it 'returns 422 (unprocessable content) http status code if an unexpected param will be added'`
**Good:**
```ruby
context 'when an unexpected param is added' do
  it { is_expected.to respond_with 422 }
end
```

---

### 4. One Expectation per Example

Each `it` block must contain exactly **one `expect`** (or `is_expected`). Multiple expectations test multiple behaviours at once — when one fails you don't know if the others passed.

**Bad:**
```ruby
it 'creates a subscription and returns success' do
  expect { subject }.to change(Subscription, :count).by(1)
  expect(subject).to be_success
end
```

**Good:**
```ruby
it { is_expected.to be_success }
it 'creates a subscription record' do
  expect { subject }.to change(Subscription, :count).by(1)
end
```

> The project's RuboCop enforces this (`RSpec/MultipleExpectations`, max: 1). Any violation will fail CI.

---

### 5. Coverage Gaps — Implementation vs. Spec

Cross-reference the implementation against the spec to find untested behaviors. For every branch, condition, rescue, and return value in the implementation, ask: is there a `context` + `it` pair that exercises it?

Common gaps to look for:

- **Branching logic** — every `if/elsif/else`, `case/when`, or guard clause should have a corresponding `context`
- **Validation failures** — each `validates` or input guard in a process should have at least one failure context
- **Error handling** — `rescue`, `on_error`, or explicit failure outputs that have no spec
- **Nil / empty inputs** — required fields set to `nil`, empty arrays, blank strings
- **Side effects** — if the implementation sends a notification, enqueues a job, or calls a gateway, the spec should assert it was (or was not) called
- **Happy path only** — specs that only test the success case and skip all failure conditions

Report each gap as: what the implementation does, which file/line it's on, and what context + assertion is missing in the spec.

Only flag what's genuinely missing — don't invent requirements beyond what the implementation visibly handles.

---

### 6. Assert Data, Not Presence

Weak assertions that only check existence or truthiness are nearly worthless — they pass even when the data is wrong. Always assert the actual values that matter.

**Bad — presence/truthiness checks:**
```ruby
expect(user).to be_present
expect(subscription).not_to be_nil
expect(result).to be_truthy
expect(response.parsed_body).to be_a(Hash)
```

**Good — assert the actual data:**
```ruby
expect(user).to have_attributes(id: 'aaa', name: 'Alice', role: 'admin')
expect(subscription).to have_attributes(status: 'activated', account_id: '123456')
expect(result).to be_success(:activation_registered)
expect(response.parsed_body['errors']).to contain_exactly("Account can't be blank")
```

Flag any assertion that would pass regardless of the actual content — it's testing that something exists, not that it's correct. The fix is always to assert on the specific attributes, values, or structure the implementation is supposed to produce.

> Exception: `be_present` / `not_to be_nil` are acceptable when the only meaningful assertion *is* existence — e.g., checking a token was generated when its value is random. Use judgment.

---

### 7. Use `expect` Syntax — Never `should`

Always use `expect(...)` or `is_expected.to`. Never use the older `should` syntax.

**Bad:** `response.should have_http_status(:ok)`
**Good:** `expect(response).to have_http_status(:ok)`

For one-liners with implicit subject, prefer:
```ruby
it { is_expected.to be_success }
```

---

### 8. Descriptions Must Not Start With "should"

Write descriptions in the third-person present tense.

**Bad:** `it 'should not change timings'`
**Good:** `it 'does not change timings'`

---

### 9. Use `subject` to DRY Up the Main Object

When multiple examples assert on the same expression, define it as `subject`. Name it when clarity helps.

**Bad:**
```ruby
it { expect(described_class.call(**attrs)).to be_success }
it { expect(described_class.call(**attrs)).to be_a(Solid::Output) }
```

**Good:**
```ruby
subject(:result) { described_class.call(**attrs) }

it { is_expected.to be_success }
```

---

### 10. Use `let` / `let!` — Not Instance Variables

Replace `before { @var = ... }` instance variable assignments with `let`. `let` is lazy (evaluated on first use, cached for the example), which is both faster and cleaner.

**Bad:**
```ruby
before { @user = FactoryBot.create(:user) }
it { expect(@user).to be_valid }
```

**Good:**
```ruby
let(:user) { FactoryBot.create(:user) }
it { expect(user).to be_valid }
```

Use `let!` only when the record must exist before the example runs (e.g., to populate a database for a query).

---

### 11. Never Use `.merge()` on a Shared Base Hash

Each `context` must define its own complete hash rather than calling `.merge()` on a base `let`. Merging hides the actual inputs and makes examples hard to read in isolation.

**Bad:**
```ruby
let(:base) { { name: 'Alice', role: 'admin' } }

context 'when role is guest' do
  let(:attrs) { base.merge(role: 'guest') }
end
```

**Good:**
```ruby
context 'when role is guest' do
  let(:attrs) { { name: 'Alice', role: 'guest' } }
end
```

> This rule is strictly enforced on this project.

---

### 12. No Helper Methods in Spec Files

Do not define private methods in spec files. Use `let`, `before`, or factories instead.

**Bad:**
```ruby
def build_payload(overrides = {})
  { name: 'Alice' }.merge(overrides)
end
```

**Good:** Define `let(:payload) { { name: 'Alice' } }` or use a factory.

---

### 13. Use Factories, Not Raw `Model.new` / `Model.create`

Test data should be created with FactoryBot. Raw `.create` or `.new` calls scatter attribute lists across specs and break when the model changes.

**Bad:** `User.create(name: 'Alice', email: 'alice@example.com', ...)`
**Good:** `let(:user) { create(:user) }`

> `create`, `build`, `build_stubbed` are available without the `FactoryBot.` prefix when using the FactoryBot syntax inclusion.

---

### 14. Mock Sparingly — Test Real Behaviour Where Possible

Stubs and mocks are appropriate for:
- External HTTP calls (use VCR cassettes or `stub_request`)
- Preventing destructive side effects in tests
- Simulating error conditions that are hard to trigger naturally

Do not mock the system under test's own collaborators just to avoid database writes. If a process depends on an ActiveRecord model, let it actually write — the test database is there for this.

**Bad:** Stubbing `Subscription.create!` in a process spec to avoid a DB write.
**Good:** Let the process write, then assert on `Subscription.last` or use `change(Subscription, :count)`.

---

### 15. Never Rescue Exceptions in Tests

If the code under test raises, assert on it with `expect { }.to raise_error(...)`. Rescuing inside an example hides the actual failure.

**Bad:**
```ruby
it 'handles invalid input' do
  begin
    subject
  rescue ArgumentError
    # ok
  end
end
```

**Good:**
```ruby
it 'raises ArgumentError for invalid input' do
  expect { subject }.to raise_error(ArgumentError)
end
```

---

### 16. No Shared Examples

`shared_examples` and `it_behaves_like` are **not used in this project**. Do not suggest or introduce them. If you see duplication across contexts, address it by extracting well-named `let` blocks or `before` hooks — not shared examples.

---

### 17. Use Hash Shorthand Syntax

When a variable name matches the key, use Ruby 3.1 hash shorthand.

**Bad:** `{ user: user, token: token }`
**Good:** `{ user:, token: }`

---

### 18. Stub HTTP Requests for External Calls

Any spec that touches an external HTTP endpoint must stub it. There are two acceptable approaches in this project:

**Bad:** Hitting a real external API in a test.

**Option A — WebMock (`stub_request`)**: Use for fine-grained control over request matching and response crafting inline.
```ruby
stub_request(:post, 'https://api.example.com/resource')
  .with(
    body: '{"key":"value"}',
    headers: { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer token' }
  )
  .to_return(status: 200, body: fixture('response.json'))
```

**Option B — VCR + WebMock**: Use for recording and replaying real HTTP interactions. Cassettes are stored in `spec/cassettes/`.
```ruby
it 'fetches the resource', vcr: true do
  # or: vcr: { cassette_name: 'my_cassette' }
  result = MyGateway.call
  expect(result).to be_success
end
```

Both are valid — flag it as a violation only when neither approach is used and a real HTTP call would be made.

---

### 19. Correct English in Descriptions

All `describe`, `context`, and `it` descriptions must be grammatically correct English. Flag spelling mistakes, wrong verb tenses, missing articles, and awkward phrasing.

Common patterns to catch:

- **Wrong verb form:** `it 'return the user'` → `it 'returns the user'` (third-person singular present)
- **Conditional in `it`:** `it 'when the token is missing'` → `it 'raises an error'` (outcome, not condition)
- **Misspelling:** `context 'when the suscription is active'` → `context 'when the subscription is active'`
- **Missing article:** `it 'creates record'` → `it 'creates a record'`
- **Wrong tense:** `it 'created the subscription'` → `it 'creates the subscription'`
- **Redundant words:** `it 'does not returns an error'` → `it 'does not return an error'`

**Bad:**
```ruby
context 'when user dont have permission' do
  it 'return a 403 error' do
```

**Good:**
```ruby
context "when the user doesn't have permission" do
  it 'returns a 403 error' do
```

---

## Output Format

Structure your review as follows:

```
## RSpec Review: <file path or class name>

### Summary
<one or two sentences: overall quality, number of violations found>

### Violations

#### <Rule Name> — line(s) N
**Problem:** <what exactly is wrong>
**Fix:**
```ruby
<corrected snippet>
```

### Suggestions (non-blocking)
<optional improvements that don't violate any rule but would make the spec cleaner>

### Verdict
✅ Looks good / ⚠️ Minor issues / ❌ Needs changes
```

If there are no violations, say so clearly and note what the spec does well.
