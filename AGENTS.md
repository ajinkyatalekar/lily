# Lily

An open-source platform for hosting and managing game servers (Minecraft first, other games later), and the hosted website built on it: customers sign up, log in, and create and manage their own servers. Customers install nothing and never see a host. We operate the whole fleet: shared cloud hosts by default, bare metal on request, all provisioned and run by us. Paid tiers charge what the infrastructure costs.

Stack: Go for the control plane and the host agent, React and TypeScript for the web app, one Docker container per game server.

Agents write, review and maintain this code. Humans decide what the product does and approve key design; they rarely read diffs. So the repo has to explain itself: if you needed something that was not written down, write it down where you looked first.

This file is for every coding agent (Claude Code, Codex, whatever comes next). `CLAUDE.md` only imports it, and the files under `.claude/`, `.agents/` and `.codex/` only point at `process/`. Never put a rule in a tool-specific file.

## Where the truth lives

| Question | Answer lives in |
|---|---|
| What are we building now, and what not yet? | `ROADMAP.md` |
| What does the system do today? | `openspec/specs/` |
| What is changing, and why? | `openspec/changes/<id>/` |
| Why was this built this way? | `git log -- <path>` (each squash commit carries its PR body), then `openspec/changes/archive/` |
| How do I work in this module? | the nearest `AGENTS.md` up the tree |
| Is my change acceptable? | `make check` |
| How does a change get from request to merge? | `process/ship.md`, with the roles beside it |

## Rules

1. **One gate.** `make check` is the whole definition of "passes", locally and in CI. Never weaken a check to go green: fix the code or escalate.
2. **Behavior changes start as a proposal, inside the active cycle.** Anything that changes what a user can do, an API, or stored data needs an approved `openspec/changes/<id>/` first, and must fit the active cycle in `ROADMAP.md`. If it does not fit, it goes under Later, not into code. Fixes that restore specified behavior, refactors and upkeep need no proposal.
3. **Tests come from scenarios.** Each spec scenario gets a test that names it. Each bug fix starts with a test that fails. Beyond that, don't pad: a test that cannot fail for a real reason is sprawl.
4. **Test the real thing.** Real database, real containers, a real game server booting. Fake only what we neither own nor can run locally.
5. **Stay in scope.** Your task names the directories you may touch. Use other modules only through their public interface. To change a contract between modules, change it first, alone, in its own PR.
6. **Reuse before writing, delete before adding.** Look for an existing helper first. No abstraction until it has two real callers. No new dependency without human approval. Never paste code from another project.
7. **Small PRs.** One change, at most 400 changed lines (specs and lockfiles excluded). CI enforces it.
8. **Declare shortcuts.** A known limit gets a `shortcut: <the limit>, <when to upgrade>` comment at the code and a line under Caveats in the PR. An undeclared shortcut is a defect.
9. **Keep module docs true.** Each module has an `AGENTS.md` of at most 40 lines: purpose, public interface, invariants, how to test it. Change any of those and you update it in the same PR.
10. **Tenant code is hostile.** Game servers run plugins and mods we did not write. Nothing a customer controls (files, commands, config, names) is trusted by the host or the control plane.
11. **This repo is public.** Never commit secrets, credentials, customer data, the addresses of our hosts, or anything under `.local/`. PR bodies, commit messages and issues are public too.

## Escalate instead of guessing

Stop and hand back when: the spec is ambiguous or wrong; the task needs files outside its scope; it needs a new dependency; it cannot fit in 400 lines; a check looks wrong; or the work touches tenant isolation, auth, billing or data deletion in a way the design did not cover.

## Human-approved paths

`.github/CODEOWNERS` makes a PR wait for a human when it touches:

- intent: `ROADMAP.md`, or a proposal, design or spec delta under `openspec/changes/<id>/`
- the process: `/AGENTS.md`, `/CLAUDE.md`, `process/`, `.claude/`, `.agents/`, `.codex/`, `.github/`, `Makefile`, `scripts/`, `openspec/config.yaml`
- dependencies: any `go.mod` or `package.json`

Everything else merges on green CI plus reviewer approval.
