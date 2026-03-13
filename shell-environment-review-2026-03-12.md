# Shell Environment Review

Date: 2026-03-12

## Scope

This review covers the current live shell configuration in `~/.zshrc`, the tracked dotfiles in `zsh/.zshrc`, `zsh/.exports`, `zsh/.aliases`, `zsh/.zshenv.sh`, `Brewfile`, and `README.md`.

It also cross-checks a few upstream references:

- Node.js official release schedule and support guidance
- direnv official hook placement guidance
- pyenv official setup and init behavior
- Homebrew stable versions for installed shell-related formulae

## Executive Summary

The shell setup works, but it is carrying a lot of historical baggage.

The biggest issues are:

1. Interactive shell startup is slow.
2. Multiple language version managers overlap and conflict.
3. PATH and environment loading are duplicated and partially contradictory.
4. The live shell config has drifted away from the repo and the README is no longer accurate.
5. A few patterns are brittle enough that future maintenance will stay expensive even if the shell is currently usable.

The measured startup numbers make this concrete:

- `zsh -i -c exit` took about `5.6s` to `7.2s` total in repeated runs.
- `openclaw completion --shell zsh` alone took about `3.3s` total.
- `pyenv init - zsh` took about `0.18s`.
- sourcing RVM took about `0.12s`.

That means the OpenClaw completion generation is the single biggest measured startup hotspot, and the rest of the shell initialization is still heavier than it should be.

## Findings

### 1. Startup latency is materially high

Severity: High

Evidence:

- `~/.zshrc:116` dynamically runs `source <(openclaw completion --shell zsh)` on every shell start.
- `zsh/.zshrc:79` runs `eval "$(command pyenv init - zsh)"`.
- `~/.zshrc:100` runs `rvm use ruby-3.4.1 --default >/dev/null 2>&1` on every shell start.
- `zsh/.exports:80` runs `eval "$(direnv hook zsh)"` during exports loading rather than in a clearly final prompt-hook section.

Why it smells:

- Anything that shells out during every interactive startup is expensive.
- Dynamic completion generation is usually better cached to a file and regenerated only when the tool changes.
- `pyenv`, `rvm`, and prompt hooks all add fixed startup tax before you type a command.

Suggestion:

- Cache OpenClaw completion output to a file and source that file instead of generating it on every shell launch.
- Keep only one Python bootstrap path and one Ruby bootstrap path in startup.
- Move prompt-affecting hooks to a deliberate end-of-file section and keep it minimal.
- Profile again with `zprof` after cleanup to verify that the next bottleneck is worth optimizing.

### 2. Node management is split between Homebrew and nvm

Severity: High

Evidence:

- `Brewfile` installs both `node` and `nvm`.
- `zsh/.zshrc:55-66` initializes `nvm`.
- Interactive `node -v` reports `v25.6.1`.
- Homebrew reports installed `node` formula `24.1.0`, stable `25.8.1`.
- Node.js official release guidance says production should use Active LTS or Maintenance LTS releases; as of this review, `v24` is Active LTS and `v25` is Current.

Why it smells:

- You effectively have two Node installation authorities.
- The shell version and the Brew formula version do not match, which proves that version ownership is unclear.
- Current Node is fine for experimentation, but LTS is the safer default for day-to-day development unless you intentionally want the newest major.

Suggestion:

- Pick one of these models:
  - Homebrew owns a single global Node, no `nvm` in startup.
  - `nvm` owns Node versions, remove Brew `node`.
- If you keep `nvm`, set the default to LTS and lazy-load it instead of initializing it eagerly in every shell.
- If you need per-project version pinning, `nvm` plus `.nvmrc` is the cleaner story than also carrying a Brew-managed global Node.

### 3. Python management is split across Homebrew, pyenv, pipx, and manual `.venv` activation

Severity: High

Evidence:

- `Brewfile` installs `python`, `pyenv`, and `pyenv-virtualenv`.
- `zsh/.zshrc:71-84` initializes `pyenv` only when `VIRTUAL_ENV` is unset.
- `zsh/.zshrc:75-84` manually sets `VIRTUAL_ENV` when a `.venv` directory exists, then activates it.
- `zsh/.zshrc:53` adds `~/.local/bin` for `pipx` tools.
- `python3 --version` is `3.11.11`, while Homebrew reports `python@3.14` installed at `3.14.2` and stable `3.14.3`.

Why it smells:

- You have several different ways to choose Python, and the active one depends on cwd and startup order.
- Manually setting `VIRTUAL_ENV` before activation is unusual and easy to forget or break.
- `pyenv-virtualenv` is installed but not visibly used.

Relevant upstream note:

- pyenv’s own docs emphasize that `pyenv` works by putting shims at the front of `PATH`, and that `eval "$(pyenv init - <shell>)"` is the shell integration path when you actually want shims and shell functions.

Suggestion:

- Pick a primary Python story:
  - `pyenv` for interpreter selection, `venv` or `uv` for project environments.
  - Or keep `.venv` activation project-local and stop initializing `pyenv` in every shell.
- If `direnv` is already part of the stack, consider using `.envrc` to activate project environments explicitly instead of auto-activating any `.venv` found in the cwd.
- Remove `pyenv-virtualenv` if you are not using it.

### 4. Ruby management is inconsistent

Severity: High

Evidence:

- `Brewfile` installs `ruby-install`.
- `~/.zshrc:4` and `~/.zshrc:98-100` initialize and actively use `RVM` instead.
- The repo does not show a corresponding `chruby`-style setup even though `ruby-install` is normally paired with `chruby`.

Why it smells:

- `ruby-install` in Brewfile and `RVM` in shell startup represent two different Ruby management models.
- This is exactly the sort of historical layering that makes shells harder to reason about.

Suggestion:

- Choose one Ruby manager and delete the other path from your setup.
- If you keep `RVM`, remove `ruby-install` unless it is used elsewhere.
- If you prefer a lighter setup, `ruby-install + chruby` is simpler than `RVM`, but only change if you want that tradeoff deliberately.

### 5. PATH construction is duplicated, reset, and partially stale

Severity: High

Evidence:

- `~/.zprofile:1` runs `brew shellenv`.
- `zsh/.zshenv.sh:18-31` builds `path` again.
- `zsh/.exports:6-12` resets `PATH` from scratch and prepends several legacy directories.
- Effective interactive `PATH` contains duplicate entries, including `/usr/local/bin` twice.
- `zsh/.exports` includes Intel-era and MacPorts paths on an Apple Silicon machine.

Why it smells:

- `brew shellenv` in `.zprofile` establishes one PATH ordering, then `.exports` effectively overrides it.
- Resetting `PATH` repeatedly makes it hard to reason about which tool wins.
- Carrying `/opt/local/*`, `/usr/local/*`, and `/opt/homebrew/*` together may be intentional, but it increases ambiguity and lookup noise.

Suggestion:

- Centralize PATH logic in one place.
- Prefer zsh arrays with uniqueness, for example `typeset -U path PATH`, instead of repeated string prepends.
- Remove directories that are not actually used on this machine.
- Keep `brew shellenv` as the single source of truth for Homebrew path injection unless you have a specific reason not to.

### 6. Environment loading from `.env` is duplicated and brittle

Severity: Medium

Evidence:

- `zsh/.exports:3` and `zsh/.aliases:3` both run `export $(grep -v '^#' $HOME/dotfiles/.env | xargs -0)`.

Why it smells:

- It is duplicated in two sourced files.
- `xargs -0` expects NUL-delimited input, but `.env` files are line-delimited.
- This pattern is fragile when values contain spaces, quotes, `#`, or shell-sensitive characters.
- Loading it from `.aliases` is especially odd because aliases should not also be part of your environment-loading pipeline.

Suggestion:

- Load `.env` once, in one place, with a parser that actually matches dotenv semantics.
- Better yet, use `direnv` for project-scoped env and keep personal long-lived secrets in a dedicated secret source, not in both exports and aliases.

### 7. Alias layer contains duplicates and surprising command shadowing

Severity: Medium

Evidence:

- `zsh/.aliases:383` and `zsh/.aliases:403` both define `alias gcm="git commit -m"`.
- `zsh/.aliases:683` defines `alias vi="nvim"`, then `zsh/.aliases:690` overrides it with `alias vi="vim"`.
- `zsh/.aliases:694` aliases `cat` to `ccat`.
- `zsh/.aliases:707-708` alias `pip` to `uv pip` and `python` to `python3`.

Why it smells:

- Duplicate aliases create maintenance noise and make intent unclear.
- The `vi` override is contradictory.
- Rebinding common commands is fine interactively if deliberate, but these particular aliases are likely to surprise you later.

Suggestion:

- Remove duplicate alias definitions.
- Decide whether `vi` should mean `vim` or `nvim`; right now it means `vim` because the later alias wins.
- Consider replacing the more opinionated aliases (`cat`, `pip`, maybe `python`) with explicit helper commands if you want less surprise.

### 8. Plugin management is half-removed rather than cleanly designed

Severity: Medium

Evidence:

- `zsh/.zshrc:12` still has a `plugins=(...)` array, but runtime loading is now direct `source` calls to files under `~/.antigen/bundles/...`.
- `zsh/.zshrc:34` and `zsh/.zshrc:100` still depend on `~/.antigen/bundles/...` paths.
- `README.md:47` still documents Antigen as the zsh plugin manager.

Why it smells:

- The runtime no longer really uses Antigen as a manager, but it still depends on Antigen’s clone layout.
- That means plugin sourcing is now tied to a cache-style directory under `~/.antigen`, which is an odd permanent dependency.

Suggestion:

- Either:
  - fully own manual sourcing from a dedicated, stable plugin directory you control in the repo, or
  - switch to a maintained static plugin loader and make that the documented path.
- Remove the stale `plugins=(...)` array if it is no longer functional.

### 9. Live shell config has drifted from the tracked repo

Severity: Medium

Evidence:

- `~/.zshrc` contains VS Code shell integration at `~/.zshrc:49`, OpenClaw completion at `~/.zshrc:116`, and a guarded GitHub Copilot plugin check at `~/.zshrc:126`.
- The tracked `zsh/.zshrc` does not include all of those live-only behaviors.

Why it smells:

- Dotfiles are most valuable when the repo is the truth.
- Once the live shell diverges from the tracked config, reproducing and reviewing behavior gets much harder.

Suggestion:

- Decide whether the repo or the live home directory is authoritative.
- If the repo is authoritative, sync the live-only changes back in a deliberate cleanup commit.
- If not, document that clearly and stop treating the repo as a deployment source of truth.

### 10. `zsh/.zshenv.sh` references a missing file

Severity: Medium

Evidence:

- `zsh/.zshenv.sh:46` sources `$HOME/dotfiles/shell/exports`.
- That path does not exist in this repo.

Why it smells:

- This is bit-rot.
- If `zsh/.zshenv.sh` is actually linked into a live shell as `.zshenv`, that source line is broken.

Suggestion:

- Either delete `zsh/.zshenv.sh` if it is unused, or repair it so it sources a real file.
- More broadly, audit which startup files are actually linked into `$HOME`.

### 11. direnv hook placement does not match the official recommendation

Severity: Low

Evidence:

- `zsh/.exports:80` runs `eval "$(direnv hook zsh)"`.
- direnv’s official docs say to add `eval "$(direnv hook zsh)"` at the end of `~/.zshrc`.

Why it smells:

- Prompt and hook manipulators are easiest to debug when they are all in the main interactive config and loaded late.

Suggestion:

- Move the `direnv` hook to the end of the interactive shell file.
- Since you already install `direnv`, consider using it more aggressively for project-local env instead of custom `.env` loading.

### 12. Documentation is stale

Severity: Low

Evidence:

- `README.md:7` still says the setup targets macOS Monterey 12.0.1.
- `README.md:47` still says Antigen manages zsh plugins.
- `README.md:59` still says `n` sets global Node to LTS, but the current shell uses `nvm`.

Why it smells:

- The docs no longer describe reality.
- Anyone reinstalling from scratch using the repo as reference will get the wrong mental model.

Suggestion:

- Update the README after the shell cleanup so it describes the actual active toolchain.

## Version Snapshot

Local shell/tool status checked on this machine:

| Tool     | Local  | Upstream/Brew stable | Notes                  |
| -------- | ------ | -------------------- | ---------------------- |
| zsh      | 5.9    | 5.9                  | Current                |
| starship | 1.22.1 | 1.24.2               | Outdated               |
| direnv   | 2.35.0 | 2.37.1               | Outdated               |
| fzf      | 0.61.0 | 0.70.0               | Outdated               |
| pyenv    | 2.6.1  | 2.6.26               | Significantly outdated |
| neovim   | 0.11.0 | 0.11.6               | Outdated               |
| tmux     | 3.5a   | 3.6a                 | Outdated               |
| gh       | 2.86.0 | 2.88.1               | Outdated               |
| nvm      | 0.40.2 | 0.40.4               | Slightly outdated      |
| ripgrep  | 15.1.0 | 15.1.0               | Current                |

Additional note:

- `brew outdated` reported `151` outdated formulae and `4` outdated casks, so this is not only a shell-config cleanup problem; package hygiene is broadly lagging.

## Patterns That Are Still Fine

Not everything here is a problem.

- `brew shellenv` in `~/.zprofile` is standard.
- `zsh-syntax-highlighting` is sourced last, which is correct.
- `zsh-completions` is added to `fpath` before `compinit`, which is also correct.
- Using `starship` is not outdated; it is still a normal modern prompt choice.
- Using `direnv` is still a good pattern; the problem is placement and overlap, not the tool itself.

## Recommended Cleanup Order

### Phase 1: remove the biggest waste

1. Cache or remove dynamic OpenClaw completion generation from startup.
2. Pick one Node manager.
3. Pick one Ruby manager.
4. Stop loading `.env` twice.

### Phase 2: simplify shell ownership

1. Make the repo config and live config match again.
2. Centralize PATH setup in one file.
3. Remove stale plugin-manager leftovers and dead arrays.
4. Fix or delete `zsh/.zshenv.sh`.

### Phase 3: tighten the interactive UX

1. Remove duplicate aliases.
2. Reconsider command-shadowing aliases that create surprise.
3. Move `direnv` to the end of `.zshrc`.
4. Update the README to match reality.

## Suggested End State

If this were being normalized for long-term maintenance, the target shape would be:

- `~/.zprofile`: login-only environment bootstrapping such as `brew shellenv`
- `~/.zshrc`: interactive shell only
- one version manager per language
- one PATH-building location
- one env-loading mechanism for personal secrets
- `direnv` for project-local env and virtualenv activation
- static or repo-owned plugin sourcing, not a dependency on a manager cache directory
- documentation that matches the live shell exactly

## Bottom Line

The setup is functional, but it is now more historical than intentional.

The most valuable improvements are not cosmetic:

- cut the startup time
- remove overlapping tool ownership
- centralize environment and PATH logic
- bring the repo back in sync with the live machine

If you do only one thing first, do this:

1. Remove dynamic OpenClaw completion generation from shell startup and replace it with a cached sourced file.

That one change is likely to buy back the biggest chunk of startup time immediately.
