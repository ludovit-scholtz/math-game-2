---
description: Tag a release that builds a signed AAB and uploads it to Google Play internal testing
argument-hint: <x.y.z>
---

Release version `$ARGUMENTS`.

1. Ensure you are on an up-to-date `main` with a clean tree
   (`git switch main && git pull --ff-only && git status`).
2. Verify the version is semver `X.Y.Z` and greater than the latest tag
   (`git tag --sort=-v:refname | head -5`). The version code is derived as
   `MAJOR*10000 + MINOR*100 + PATCH`, so MINOR and PATCH must be < 100.
3. Confirm CI is green on `main`: `gh run list --branch main --limit 3`.
4. **Ask the user to confirm** before pushing the tag — it publishes to Google Play.
5. `git tag v$ARGUMENTS && git push origin v$ARGUMENTS`
6. Watch the run: `gh run list --workflow release.yml --limit 1` then
   `gh run watch <id>`. Report the result; on failure show the failing step log
   (`gh run view <id> --log-failed`).

`pubspec.yaml`'s `version:` is rewritten from the tag in CI; don't bump it by hand.
