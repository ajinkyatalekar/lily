# `make check` is the single gate: what passes here passes CI, and nothing else counts.
# shortcut: only process checks exist, Cycle 1 adds fmt/lint/types/tests/module-boundary/file-size/e2e here.

OPENSPEC := npx -y @fission-ai/openspec@1.13.0
BASE ?= origin/main

.PHONY: check diff-size checkpoint

check:
	$(OPENSPEC) validate --all --strict --no-interactive
	@! scripts/check-pr-body.sh < .github/pull_request_template.md >/dev/null \
		|| { echo "check-pr-body.sh accepts an unfilled template"; exit 1; }
	@cmp .claude/skills/ship/SKILL.md .agents/skills/ship/SKILL.md # one pointer, two tools
	@test -z "$$(git ls-files .local)" || { echo ".local/ is private and must never be committed"; exit 1; }

# AGENTS.md rule 7. CI runs this on pull requests; it needs BASE fetched.
# shortcut: generated code is not excluded because there is none yet, add its path here when codegen lands.
diff-size:
	@d=$$(git diff --numstat $(BASE)...HEAD -- . ':(exclude)openspec' ':(exclude)LICENSE' ':(exclude)*.lock' ':(exclude)*-lock.*' ':(exclude)*.sum') || exit 1; \
	n=$$(printf '%s\n' "$$d" | awk '{s += $$1 + $$2} END {print s + 0}'); \
	echo "changed lines: $$n (max 400)"; [ "$$n" -le 400 ]

# End of a cycle (ROADMAP.md). Fails while any change is still open, then lists every declared shortcut for the human sign-off.
checkpoint: check
	@open=$$(find openspec/changes -mindepth 1 -maxdepth 1 -type d ! -name archive); \
	if [ -n "$$open" ]; then echo "open changes, finish or remove them:"; echo "$$open"; exit 1; fi
	@echo "declared shortcuts:"; git grep -nE '(#|//|<!--|/\*) ?shortcut:' || echo "  none"
