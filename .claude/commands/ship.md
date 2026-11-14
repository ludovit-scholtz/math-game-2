---
description: Branch, commit, open a PR, review it, fix findings, re-review and merge
argument-hint: [short description of the change]
---

Ship the current work: $ARGUMENTS

1. **Branch** — if on `main`, create `feat/…`, `fix/…`, `chore/…` or `docs/…`.
   Only include files that belong to this change; leave unrelated working-tree
   edits unstaged and mention them to the user.
2. **Verify** — run `/check` (analyze + tests must pass).
3. **Commit** — conventional commit message (`feat: …`, `fix: …`).
4. **PR** — `git push -u origin HEAD` then `gh pr create --base main` with a
   summary, a test-plan checklist and any user-visible rule changes.
5. **Review** — run `/code-review` on the branch. Also check against AGENTS.md:
   every locale in `AppStrings.supportedLocales` updated, rules/docs in sync, `lib/logic` stays Flutter-free,
   storage keys backward compatible, tests cover the change.
6. **Fix** — apply valid findings in a new commit, re-run `/check`, push.
7. **Re-review** — repeat steps 5–6 until no actionable findings remain.
8. **CI** — `gh pr checks --watch`; fix failures.
9. **Merge** — unless the user explicitly asked you to merge in this request,
   show the PR summary and **ask for confirmation first**. Then
   `gh pr merge --squash --delete-branch`, then
   `git switch main && git pull --ff-only`.

Summarise the PR URL, review findings and how each was resolved.
