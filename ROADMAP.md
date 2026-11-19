# Roadmap

Work happens in cycles. One cycle is active at a time. It has a fixed scope and ends at a checkpoint that a human signs off. Nothing outside the active scope gets built.

## How a cycle runs

1. **Scope.** The cycle's section lists what is in, what is out, and its exit checklist. A human approves it; this file is human-owned.
2. **Build.** Every proposal names its cycle and must fit that cycle's In list. A good idea that does not fit is added under Later and not built.
3. **Checkpoint.** `make checkpoint` passes, every box in the exit checklist is true, and a human has done the walkthrough. One PR then moves the cycle to Done and writes the next cycle's scope in full.

A feature is finished only when its change is archived, every scenario including the failure ones has a test, a user can reach it in the web app, its module docs are true, and every shortcut it took is declared. At a checkpoint a half-built feature is finished or removed. It is never carried into the next cycle.

## Active: Cycle 0, Process

Goal: the pipeline exists and has been used once.

- [x] Rules, roles, PR template and CI are in the repo
- [ ] GitHub repo with required CI on `main` and squash merge only
- [ ] Code-owner review enforced, which needs agents to open PRs under a GitHub identity other than the owner's
- [ ] CI green on `main`
- [ ] The Cycle 1 proposal is approved

## Next: Cycle 1, Walking skeleton

Goal: one of us, acting as operator, takes a fresh host to a running Minecraft server they can join and control from the browser, and every gate in `make check` is real. The web app in this cycle is our own operator view. The customer site starts in Cycle 2.

In:

- Enroll a host by starting the host agent with a one-time token. It shows as online or offline.
- Create a Minecraft (Java) server on a chosen host. Start, stop and delete it.
- Live console in the web app: output as it happens, and commands sent to the server.
- The server's address shown as host IP and port.
- One operator secret protecting the whole API.
- An end-to-end test that boots the whole stack and a real Minecraft server, pings it as a client would, sends a console command, then stops and deletes it.
- `make check` gains formatting, lint, types, tests, module-boundary rules, a file-size cap and the end-to-end test.

Out, even where it looks easy:

- Accounts, login, permissions, plans and billing
- Files, SFTP, backups, and server settings beyond version and memory
- Subdomains, proxies, DDoS protection
- Choosing a host automatically, moving servers, production deployment
- Modpacks, plugins, Bedrock, other games
- Visual design, a component kit, and a product name: the web app is plain and functional

Exit checklist:

- [ ] Every Cycle 1 change is archived and `make checkpoint` passes
- [ ] `make check` runs every gate above in CI in under 10 minutes
- [ ] The end-to-end test passes 10 times in a row
- [ ] A human goes from a clean clone to joining the server from a Minecraft client in under 15 minutes, using only the README
- [ ] Every module has a true `AGENTS.md`
- [ ] Each shortcut is paid off or named in the next cycle's scope
- [ ] A janitor run finds nothing it would fix

## Later

In order. Each is scoped in full only when it becomes Next.

2. **Accounts and ownership.** The customer site begins: sign up, log in, create and manage your own servers. Every server belongs to a customer and every API call is authorized. Customers never see hosts, so a new server is placed on one automatically by the simplest rule that works. The Cycle 1 screens become the operator view.
3. **Look and feel.** Product name. A visual direction chosen by a human. Design tokens, and everything built so far restyled.
4. **A server worth keeping.** Version and server type, memory limits and live stats, restart on crash, file manager, backups and restore.
5. **Addresses.** A stable subdomain per server (`name.<domain>`, domain not chosen yet).
6. **Fleet.** Many hosts, placement by capacity, shared cloud and bare-metal classes, draining a host and moving its servers, an operator view.
7. **Plans and billing.** Paid tiers priced at what the infrastructure costs, payment, suspension when unpaid.
8. **Protected ingress.** A DDoS-protected entry point in front of the hosts that keeps `online-mode=true` working and preserves player IPs.
9. **Launch readiness.** Production deployment, monitoring and alerts, control-plane backups, abuse handling.
10. **Packs.** Light modpacks and plugin sets installed in one step, including in-game password login.
11. **Second game.** The seam between Lily and a game gets designed here, once it has two real callers.

## Done

Nothing yet.
