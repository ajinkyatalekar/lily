## Why

Cycle 1 (Walking skeleton) needs the whole stack standing before any game server can run. This change builds that stack with the thinnest real behavior on top, so every layer, test and gate is proven on something small before the harder changes arrive.

## What Changes

After this change an operator can:

- Open the web app and unlock it with the operator secret.
- Add a host and receive a one-time token with the command to run on that machine.
- Start the host agent with the token and watch the host turn online.
- See the host turn offline when its agent stops, and online again when it returns, with no new token.
- Issue a fresh token for a host whose token expired or whose machine was rebuilt.
- Remove a host, which cuts its agent off for good.

To carry that, the repo gains:

- A Go control plane, a Go host agent, a React web app, and one contract between them.
- `make check` running formatting, lint, types, tests, contract checks, a file-size cap, and an end-to-end test of the list above.
- A README that takes a clean clone to a running stack.

## Out of scope

- Game servers, containers and the console. Those are the next two Cycle 1 changes (`server-lifecycle`, then `live-console`).
- Accounts and login. One shared operator secret is the only access control.
- Installing the agent as a system service, upgrading it, or deploying anything to production.
- Host capacity, metrics, classes (shared cloud or bare metal) and automatic placement.
- Visual design.

## Capabilities

### New Capabilities

- `operator-access`: the operator secret that protects every operator API call and unlocks the web app.
- `host-enrollment`: adding and removing hosts, the one-time enrollment token, the host credential, and online or offline status.

### Modified Capabilities

None.

## Impact

- New top-level modules: `proto/`, `gen/`, `controlplane/`, `hostagent/`, `web/`, `e2e/`.
- New dependencies, each listed with its reason in `design.md`. Approving this proposal approves them.
- `Makefile` and CI change, so the first task's PR waits for a human.
- Building and testing now needs Go, Node and Docker installed.
