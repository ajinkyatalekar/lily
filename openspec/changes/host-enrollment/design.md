## Context

The repo holds only process files. Three things are fixed: Go for the control plane and host agent, React for the web app, and one Docker container per game server on hosts we operate. This change sets shapes the rest of Cycle 1 builds on, so the decisions below are larger than the behavior that ships.

## Goals / Non-Goals

**Goals:**

- One contract toolchain for both boundaries (web to control plane, agent to control plane), with breaking changes caught by a gate.
- No inbound management port on a game host.
- A clean clone needs only Go, Node and Docker. Every other tool is pinned in the repo.
- Nothing here makes a running game server depend on the control plane being up.

**Non-Goals:**

- More than one control-plane instance. Nothing prevents it later: host status lives in the database, not in memory.
- Mutual TLS, agent self-update, a service installer.
- A push channel from control plane to agent. `server-lifecycle` adds it when there is something to push.

## Decisions

### 1. One Go module, with boundaries the compiler enforces

`controlplane/` and `hostagent/` each keep their code under their own `internal/`, so neither can import the other. The only thing they share is `gen/`, generated from `proto/`. `web/` is a separate npm package. `e2e/` drives the built binaries from outside.

Rejected: one Go module per component. It gives the same isolation with three dependency sets to keep in step, and a lint rule would still be needed inside each.

### 2. Protobuf and Connect RPC for both boundaries

Every call the web app or the agent makes is defined in `proto/`. `buf` lints the contract and fails the build on a breaking change against `main`. Generated Go and TypeScript are committed, and a gate fails when they are stale.

Rejected: REST with OpenAPI for the web app plus hand-written JSON messages for the agent. That is two contract systems, and the agent side would be checked only at runtime.
Rejected: gRPC. Browsers cannot call it without a proxy. Connect serves browsers and Go clients from one handler, and stays readable with `curl`.

### 3. The agent calls; the control plane never calls a host

The browser talks only to the control plane, and so does the agent. A host needs no public management port and no certificate of its own.

In this change the agent makes two plain calls: enroll once, then report in every 10 seconds. `server-lifecycle` will add one long-lived server-streaming call on which the control plane pushes the desired state of that host, while the agent keeps reporting with plain calls. Each direction stays a typed call that can be retried and tested alone.

Rejected: the control plane calling each host, and the browser connecting straight to the host for the console. Every host would expose a management endpoint to the internet, which is also the first thing an attacker would flood. The cost of our choice is that console bytes, and later file bytes, pass through the control plane. That is fine for a console and must be revisited for files and backups in Cycle 4.
Rejected: one bidirectional stream for everything. It turns every message into a case of one large union type, with hand-made acknowledgements.

### 4. Status is computed from the last report

Each report stamps `last_seen_at` in Postgres. A host is `online` when that stamp is under 30 seconds old, `pending` when it has never enrolled, and `offline` otherwise. Nothing is held in memory, so a control-plane restart loses nothing. The 10-second, 30-second and one-hour limits are settings whose defaults are the spec values, so tests run in seconds.

Rejected: tracking open connections in memory. It breaks on restart and with a second instance.

### 5. Three secrets, each stored only as a hash

- Operator secret: read from the environment and compared in constant time.
- Enrollment token: 32 random bytes, one hour, single use. Only its SHA-256 is stored.
- Host credential: 32 random bytes, returned once by enrollment. Only its SHA-256 is stored. The agent keeps it in a file with mode 0600.

Exchanging a one-time token means the long-lived credential never passes through the web app or an operator's clipboard.

Rejected: a static per-host secret pasted into the agent's config. It is simpler, but the long-lived secret is shown to a human and tends to end up in shell history and chat.
Rejected for now: mutual TLS with a certificate per host. It is stronger and needs a certificate authority and rotation. Revisit in the Fleet cycle.

### 6. Postgres, plain SQL, generated queries

Migrations are forward-only SQL files embedded in the binary and applied at start under an advisory lock. `sqlc` generates typed Go from the SQL. Tests run against a real Postgres that `make check` starts in Docker.

Rejected: an ORM. It hides the SQL an agent needs to read, and adds behavior to get wrong.
Rejected: a migration library. Forward-only migrations are about forty lines of our own.
Rejected: SQLite. One writer only, and we would move to Postgres before launch anyway.

### 7. A plain React app

React, TypeScript and Vite. The generated client makes the calls, and TanStack Query handles polling and refetching. No router, component kit or CSS framework: there is one page and an unlock screen, and Look and feel is a later cycle. Browser tests use Playwright against the real stack.

### 8. Tools are pinned in the repo

`buf`, the protobuf plugins, `sqlc` and `golangci-lint` are tool dependencies in `go.mod` and run with `go tool`. Web tools are dev dependencies run with `npx`. No agent or CI runner installs anything beyond Go, Node and Docker.

## New modules

| Module | Why it exists |
|---|---|
| `proto/` | the contract, the only thing both sides agree on |
| `gen/` | Go generated from `proto/`, never edited by hand |
| `controlplane/` | API, storage, serving the web app |
| `hostagent/` | the process on each host |
| `web/` | the operator's interface |
| `e2e/` | starts the real stack and tests it from outside |

## New dependencies

| Dependency | Where | Why it cannot be avoided |
|---|---|---|
| `connectrpc.com/connect` | control plane, agent | the RPC layer of decision 2 |
| `google.golang.org/protobuf` | `gen/` | runtime for generated Go |
| `github.com/jackc/pgx/v5` | control plane | Postgres driver |
| `react`, `react-dom` | web | the chosen stack |
| `@connectrpc/connect`, `@connectrpc/connect-web`, `@bufbuild/protobuf` | web | runtime for the generated client |
| `@tanstack/react-query` | web | polling and refetching without hand-made state |
| Dev only, Go: `buf`, `protoc-gen-go`, `protoc-gen-connect-go`, `sqlc`, `golangci-lint` | build | contract checks, code generation, lint |
| Dev only, web: `typescript`, `vite`, `@vitejs/plugin-react`, `@bufbuild/protoc-gen-es`, `@biomejs/biome`, `@playwright/test` | build | type-check, bundle, generate, lint and format, browser tests |
| `postgres` container image | tests | a real database in `make check` |

## Risks / Trade-offs

- [Auth] One shared operator secret gives no per-person access and no audit trail. → Acceptable only because nothing is deployed in Cycle 1. The control plane refuses to start without a strong one, and Cycle 2 replaces it with accounts.
- [Auth] A host credential is a bearer secret. Anyone who reads the file can report in as that host. → File mode 0600, only a hash stored on our side, and re-enrolling replaces it at once. Mutual TLS in the Fleet cycle.
- [Auth] An agent could be pointed at a plain-text address and leak its token. → It refuses unless started in development mode.
- [Tenant isolation] Not exercised yet: this agent cannot run anything. → `server-lifecycle` carries the container hardening design.
- [Data deletion] Removing a host deletes its row and credential, and nothing else refers to hosts yet. → `server-lifecycle` must decide what removal means once servers live on a host.
- [Availability] All management traffic passes through one control plane. → Game servers must keep running without it; that is a requirement on `server-lifecycle`.
- [Review load] Generated code is committed, so diffs are large. → It is excluded from the 400-line limit, and a gate proves it is current.
- [Flaky tests] The end-to-end tests depend on time limits. → Limits are settings, and the exit checklist requires 10 passes in a row.

## Open Questions

- Where the control plane will be deployed, which decides how TLS is terminated. Needed by Launch readiness, not by this cycle.
