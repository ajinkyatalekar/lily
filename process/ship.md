# Shipping a change

For the orchestrator: the session a human asked to get something built. You decompose, dispatch and integrate. You do not write product code and you do not review it. Rules: `/AGENTS.md`.

## 1. Classify

- **Outside the active cycle** in `ROADMAP.md`: stop. Tell the human, and offer to add it under Later.
- **Behavior change**: what a user can do, an API, or stored data changes. Go to 2.
- **Fix, refactor or upkeep**: behavior in `openspec/specs/` is restored or unchanged. Write a brief (what, why, directories in scope, how we will know it worked) and go to 4.

When unsure, it is a behavior change.

## 2. Propose

If `.local/NOTES.md` exists in the main checkout, read it first: it holds guidance that is deliberately kept out of git. Read the `AGENTS.md` of every module the change touches. Then write the change with the `openspec-propose` skill, and open a PR that contains only `openspec/changes/<id>/`.

## 3. Human gate

Stop until a human approves and merges the proposal PR. This is the one routine human step: do not start implementing early, and do not answer the proposal's open questions yourself.

## 4. Implement

One implementer per task, each a fresh agent in its own git worktree (see Starting an agent). Tasks whose directory scopes do not overlap run in parallel; the rest run in order. Give each implementer only:

- the change id and task number (or the brief)
- the directories it may touch

It returns a PR number or the reason it stopped.

## 5. Review

One fresh reviewer per PR, in its own worktree. When both tools are set up, use the one that did not write the code: different models miss different things. Give it only the PR number and the change id (or the brief). Never pass the implementer's summary or your own view of the diff: the reviewer's value is that it has neither.

- `approve`: go to 6.
- `changes-requested`: send the findings verbatim to the same implementer, then start a fresh reviewer. After two rounds without approval, escalate with both positions.
- `escalate`: go to the human.

## 6. Merge

CI green and reviewer approved: `gh pr merge --squash --auto`. The PR body becomes the commit body, which is how later agents learn why the code is the way it is. The last task of a change archives it with the `openspec-archive-change` skill.

## Escalating

Bring the human one question, the options, and your recommendation. Keep working on whatever the answer does not block.

## Starting an agent

An agent here is a fresh session that is given a role file from this directory plus the inputs listed above, and nothing else.

| You are running in | Same tool | The other tool |
|---|---|---|
| Claude Code | subagent `implementer`, `reviewer` or `janitor` (`.claude/agents/`, each gets its own worktree) | `codex exec -C <worktree> "<prompt>"` |
| Codex | subagent `implementer`, `reviewer` or `janitor` (`.codex/agents/`) | `claude -p "<prompt>"`, run inside the worktree |

Where the tool does not make a worktree for you: `git worktree add ../lily-<branch> -b <branch>`. The prompt for the other tool is `Follow process/<role>.md.` followed by the inputs.
