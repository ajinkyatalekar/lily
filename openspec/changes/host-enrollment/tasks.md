Each task is one PR of at most 400 changed lines (generated code and lockfiles excluded) and may touch only the directories it names. Every module task also creates or updates that module's `AGENTS.md`.

## 1. Toolchain and gates

- [ ] 1.1 Pin the toolchain and wire the gates: `go.mod` with the Go version and tool dependencies, `web/package.json` with dev tools, and `make check` running format, lint, vet, tests, type-check and a 400-line cap on hand-written source files, with CI installing Go and Node. Touches `/go.mod`, `/go.sum`, `/.golangci.yml`, `/Makefile`, `/.github/workflows/`, `/scripts/`, and config files only in `/web/`. Verify: `make check` passes locally and in CI, and fails when a 401-line Go file is added.
- [ ] 1.2 Add the scenario-coverage gate: `make check` fails when a scenario in `openspec/specs/` has no test that names it. Touches `/scripts/`, `/Makefile`. Verify: the script's own test passes against a fixture spec with one covered and one uncovered scenario.

## 2. Contract

- [ ] 2.1 Define the operator API (add, list, issue token, remove host) and the agent API (enroll, report in) in `/proto/`, generate Go into `/gen/` and TypeScript into `/web/src/gen/`, and gate on contract lint, breaking changes against `main`, and generated code being current. Touches `/proto/`, `/gen/`, `/web/src/gen/`, `/buf.yaml`, `/buf.gen.yaml`, `/Makefile`. Verify: `make check` passes, and fails after a `.proto` edit that is not regenerated.

## 3. Control plane

- [ ] 3.1 Storage: forward-only SQL migrations embedded in the binary and applied at start, the `hosts` table holding token and credential hashes, and typed queries. `make check` starts a real Postgres for tests. Touches `/controlplane/`, `/Makefile`. Verify: store tests pass against real Postgres, including applying migrations twice.
- [ ] 3.2 Operator access: the control-plane binary, refusal to start without a strong secret, and rejection of operator calls without it. Touches `/controlplane/`. Verify: one test named for each of the five API scenarios in `operator-access`.
- [ ] 3.3 Operator host API: add, list, issue a new token, remove. Touches `/controlplane/`. Verify: tests named for the add, duplicate, invalid name, token not shown again, earlier token cancelled, and both remove scenarios.
- [ ] 3.4 Agent API: enroll and report in, token expiry and single use, credential replacement, and status computed from the last report. Touches `/controlplane/`. Verify: tests named for the token, credential and status scenarios, using an injected clock for the one-hour and 30-second limits.

## 4. Host agent

- [ ] 4.1 The agent binary: enroll with a token, store the credential readable only by its user, report in on an interval, retry with backoff while the control plane is unreachable, exit when its credential is rejected, and refuse an unencrypted address outside development mode. Touches `/hostagent/`. Verify: tests named for the six agent scenarios, run against a stub of the agent API built from the contract.

## 5. End to end

- [ ] 5.1 A harness in `/e2e/` that starts Postgres, the control plane and an agent as real processes with short time limits, and API-level tests of the whole story: add, enroll, online, agent stops, agent hangs, agent returns, control plane restarts, new token replaces credential, remove. Touches `/e2e/`, `/Makefile`. Verify: `make check` runs it, and it passes 10 times in a row.

## 6. Web app

- [ ] 6.1 The web shell: React app using the generated client, the unlock screen, the secret kept for the tab only, and the control plane serving the built app. Browser tests run against the harness from 5.1. Touches `/web/`, `/e2e/`, `/controlplane/` (static file serving only). Verify: browser tests named for the three web scenarios in `operator-access`.
- [ ] 6.2 The hosts page: list refreshed every 5 seconds, add with the token and command shown once, issue a new token, remove with confirmation. Touches `/web/`, `/e2e/`. Verify: browser tests named for the four web scenarios in `host-enrollment`.

## 7. Finish

- [ ] 7.1 Write the README quickstart from a clean clone to an online host, and add the module map to the root `AGENTS.md`. Touches `/README.md`, `/AGENTS.md`. Verify: a fresh clone following only the README reaches an online host, and every module has an `AGENTS.md` of at most 40 lines.
- [ ] 7.2 Archive this change with the `openspec-archive-change` skill. Touches `/openspec/`. Verify: `make check` passes with every archived scenario covered by a named test.
