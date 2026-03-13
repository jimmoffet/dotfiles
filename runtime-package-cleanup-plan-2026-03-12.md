# Runtime Package Cleanup Plan

Date: 2026-03-12

## Goal

Remove the old Homebrew-managed Node and Python ownership paths only after the new `nvm` and `uv` workflow has been exercised in normal development and validated outside this dotfiles repo.

This plan is intentionally conservative. The shell and dotfiles now treat `nvm` as the Node owner and `uv` as the Python workflow owner, but the older Homebrew packages may still exist on disk and may still be used by unrelated scripts until they are explicitly removed.

## Packages To Revisit

- `node`
- `python`
- `pyenv`
- `pyenv-virtualenv`

These are candidates for removal after validation.

## Preconditions

Do not remove the packages yet unless all of the following are true:

1. `nvm` is successfully used in at least one repo with either `.nvmrc` or an explicit `nvm use --lts` flow.
2. `uv init` and `uv venv` have been used successfully in at least two normal Python workspaces, including one opened in VS Code.
3. VS Code is correctly selecting `.venv` interpreters and no longer drifts back to pyenv-managed or global interpreters during ordinary use.
4. Any scripts that still assume `pyenv` or Homebrew `python` have been identified and either updated or intentionally left alone.
5. Jupyter or notebook workflows, if important, have been checked once with a uv-managed environment.

## Validation Checklist Before Removal

Run these checks in a fresh shell before uninstalling anything:

```sh
command -v nvm
node -v
nvm current

command -v uv
uv python list

env -u VIRTUAL_ENV zsh -ic 'echo VIRTUAL_ENV:${VIRTUAL_ENV:-unset}; echo nvm:${+functions[nvm]}; echo pyenv_fn:${+functions[pyenv]}'

brew list --formula | grep -E '^(node|python|pyenv|pyenv-virtualenv)$'
```

In VS Code, verify these behaviors manually:

1. Open a Python project that uses `.venv`.
2. Confirm the selected interpreter points at the workspace `.venv`.
3. Open a new terminal in that workspace and confirm the terminal activates the correct environment.
4. Run a Python file, tests, and one debugger session.

## Removal Order

Use the smallest blast radius first.

### Phase 1: Remove pyenv ownership tools

If there is no remaining workflow that depends on `pyenv`, remove it first:

```sh
brew uninstall pyenv pyenv-virtualenv
```

Then verify:

```sh
command -v pyenv || true
env -u VIRTUAL_ENV zsh -ic 'echo pyenv_fn:${+functions[pyenv]}; echo uv:$(command -v uv >/dev/null && echo yes || echo no)'
```

Expected result:

- `pyenv` command no longer resolves from Homebrew
- no `pyenv` shell function is initialized
- `uv` still resolves normally

### Phase 2: Remove Homebrew Python

Only do this if you do not depend on the Brew `python3` binary as a fallback interpreter outside uv-managed projects.

```sh
brew uninstall python
```

Then verify:

```sh
command -v python3 || true
uv python list
uv run python --version
```

Expected result:

- `uv` can still provision and run Python
- project `.venv` creation still works
- VS Code still resolves workspace `.venv` interpreters

Note:

macOS may still expose a system Python launcher or Xcode-provided interpreter. That is acceptable as long as your development workflow no longer depends on Brew Python ownership.

### Phase 3: Remove Homebrew Node

Only do this once `nvm` has been validated in your actual Node repos.

```sh
brew uninstall node
```

Then verify:

```sh
command -v node || true
zsh -ic 'nvm use --lts >/dev/null && node -v'
```

Expected result:

- `node` remains available in shells where `nvm` is loaded
- `.nvmrc`-driven repos still resolve the expected version

## Rollback Plan

If any removal causes breakage, restore only the missing package rather than undoing all cleanup:

```sh
brew install pyenv pyenv-virtualenv
brew install python
brew install node
```

After reinstalling, re-open a fresh shell and repeat the validation commands.

## Residual Risks

- Some older scripts may still call `python3` directly and expect a globally installed interpreter.
- Jupyter kernels may need to be reselected manually after interpreter cleanup.
- Any tool launched outside an activated shell may still rely on PATH ordering you have not simplified yet.
- A future reinstall from `code_extensions.txt` may still include extra Python-management extensions even though the core interpreter settings now prefer `.venv` plus uv.

## Recommended Timing

Wait until you have used the new setup in normal work for at least a couple of real repos, then remove packages in this order:

1. `pyenv` and `pyenv-virtualenv`
2. `python`
3. `node`

That order gives you the cleanest signal about what actually breaks and keeps rollback simple.
