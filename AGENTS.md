# StableDart

Flutter desktop port of StabilityMatrix (LykosAI). Linux, Windows, and macOS
only — no Android, iOS, or Flutter web builds. The web presence is the GitLab
Pages landing page under `public/`.

## Layout

- `lib/models`, `lib/services`, `lib/state` — ported core logic
- `lib/views/pages` — one file per top-level page; inference cards live under
  `lib/views/pages/inference/cards/`
- `lib/views/widgets`, `lib/views/shell` — shared widgets and the nav shell
- `test/` — unit, widget, and golden tests (`test/goldens/*.png`)

## Verification

- `flutter analyze` must report no issues.
- `flutter test --coverage` must pass with 100% line coverage.
- Goldens: `flutter test test/golden_test.dart --update-goldens` and commit
  the PNGs.
- Add tests for everything new.

## Commits

- Conventional Commits, description in Simplified Chinese.
- `git config core.hooksPath .githooks` installs the commit-msg hook that
  prefixes non-conventional subjects with `misc:`.
- No co-author trailers or generated-by lines.

## CI

- `.gitlab-ci.yml` runs github-sync, auto-release (cocogitto), release sync,
  and GitLab Pages. Every job must carry `tags: [linux-truenas]`.
- `.github/workflows/build.yml` builds the desktop targets only.
- Versioned releases come exclusively from cocogitto `v*` tags — no nightly
  builds.
