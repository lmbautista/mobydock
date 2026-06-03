# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project does

Mobydock is a Ruby CLI wrapper around `docker-compose` that adds environment-aware shortcuts. Usage: `mobydock [ENVIRONMENT] [COMMAND] [ARGS...]`.

All configuration is read from environment variables at runtime by `Configuration`. The core two:

- `MOBYDOCK_PATH` — absolute path to the dockerized project
- `MOBYDOCK_ENVS` — comma-separated list of valid environments (e.g. `development,integration,production`)
- `MOBYDOCK_PROTECTED_ENVS` — comma-separated list of environments where the db service is guarded against destructive operations (see "Database protection")

The remote/`docker-machine` and deploy features are gated behind further env vars, several of which support a per-environment override (`_<ENV>` suffix, uppercased) that falls back to a global default:

- `MOBYDOCK_MACHINE_MAP` — `env:machine,env:machine` pairs; absence means commands run locally
- `MOBYDOCK_DB_SERVICE` — service name used by `backup-db`/`restore-db` and to identify the db for protection
- `MOBYDOCK_MACHINE_CREATE_OPTS[_<ENV>]` — extra `docker-machine create` flags (driver is hardcoded to `amazonec2`)
- `MOBYDOCK_ELASTIC_IP_ALLOC_<ENV>` — AWS Elastic IP allocation id assigned on `launch`
- `MOBYDOCK_DEPLOY_SERVICES[_<ENV>]` — `service=image,service=image` pairs for `deploy`
- `MOBYDOCK_MIGRATE_SERVICE[_<ENV>]` — service to run `rails db:migrate` on during `deploy`

Per-environment compose files are expected at `MOBYDOCK_PATH/docker-compose-<env>.yml`.

## Commands

Ruby 3.1.0 (managed via RVM, see `.ruby-version`). Always run tests through
`bundle exec` — without it the globally-installed `railties` auto-loads a
minitest plugin that conflicts with the bundled minitest (`superclass mismatch
for ProfileReporter`).

```sh
# Run all tests (test/mobydock_test.rb requires every test/mobydock/*_test.rb)
bundle exec ruby -Ilib -Itest test/mobydock_test.rb

# Run a single test file
bundle exec ruby -Ilib -Itest test/mobydock/commands_test.rb

# Lint
bundle exec rubocop

# Auto-fix lint issues
bundle exec rubocop -a
```

## Architecture

The execution flow is: `bin/mobydock` → `Runner#call` → `Commands.*` (returns a shell string) → `exec`.

**Key design pattern:** every method in `Commands` and `Helpers` returns a shell command string — nothing is executed inside Ruby. `bin/mobydock` calls `exec runner.call` to hand off to the shell. The one exception is `Runner#docker_running?`, which actually runs `docker info` to short-circuit with an error message when Docker is down.

- `bin/mobydock` — entry point; parses `ARGV` as `[env, command, *args]` and delegates to `Runner`
- `Runner` — orchestrates validation and dispatches to the right `Commands` method; includes `Commands`, `Helpers`, and `Validator`
- `Commands` — pure module functions that build and return shell command strings (steps collected in an array, joined with ` ; `)
- `Helpers` — returns usage/error strings for display via `echo`
- `Configuration` — resolves all env vars (see "What this project does")
- `Validator` — single utility: `Validator.blank?(value)`

**Adding a command** touches four places in lockstep: add the constant to `Commands::LIST`, a `when` branch in `Runner#dispatch`, a `perform_*` guard method in `Runner`, and the builder in `Commands`. The `perform_*` method validates inputs and returns the matching `Helpers.*` usage string when something is blank, otherwise calls into `Commands.*`. Commands not in `Commands::LIST` fall through `Runner#call` to `perform_default`, which forwards the raw args to `docker-compose`.

**Remote/machine awareness:** when `MOBYDOCK_MACHINE_MAP` maps an env to a `docker-machine`, command builders prepend `eval $(docker-machine env <machine>)` via `machine_activate_cmd`, so the same command runs locally or against a remote EC2 host depending only on config. `launch`/`start`/`login` and the AWS Elastic IP wiring (`assign_elastic_ip_cmd`, which shells out to `aws ec2`) only fire when the corresponding env vars are present.

**Prompt env:** `Commands.login` appends `echo 'export MOBYDOCK_ENV=<env>'` to its output, so `eval $(mobydock <env> login)` leaves `MOBYDOCK_ENV` set in the shell. `Commands.logout` does the inverse: `docker-machine env -u ; echo 'unset MOBYDOCK_ENV'`, so `eval $(mobydock <env> logout)` disconnects and clears it. `shell/mobydock-prompt.sh` is a pure-shell snippet (no Ruby invocation per prompt render) that renders it like the git branch.

**Machine lifecycle:** `launch`/`start` create or start the `docker-machine`, `destroy` removes it (`docker-machine rm -y`, which also terminates the remote EC2 instance). `destroy` is gated on `--force` in `perform_destroy` (returns `Helpers.destroy_protected` otherwise). `mobydock ls` is a top-level, env-less command handled by `machine_ls?` in `Runner#call` (before the `docker_running?` check) that maps to `docker-machine ls`.

**Database protection:** `Runner#call` calls `db_protected?` before dispatch/`perform_default`. When the env is in `MOBYDOCK_PROTECTED_ENVS` (`Configuration.protected_env?`) and the command targets `MOBYDOCK_DB_SERVICE`, the command is refused with `Helpers.db_protected` unless `--force` is passed. `Runner#initialize` consumes `--force` from `args` (so it is never forwarded to `docker-compose`) into `@force`. `db_targets` maps each command to the services it would affect: `reset`/`update` → the service arg, `update-all` → its service keys, `restore-db` → always the db, and the destructive passthroughs (`DESTRUCTIVE_PASSTHROUGH = down/rm`) → the explicit service args or all services (incl. db) when none given. `deploy` is intentionally not guarded.

The stop passthroughs (`STOP_PASSTHROUGH = stop/kill`) only halt containers (data survives in volumes), so they are guarded differently: they refuse only when the db is named explicitly. A bare `stop`/`kill` in a protected env is *not* blocked — `Runner#stop_excluding_db?` routes it to `Commands.stop_excluding_db`, which stops every service *except* the db (via `docker-compose config --services | grep -vx <db>`). Passing `--force` falls through to `Commands.default` and stops everything including the db. If `MOBYDOCK_DB_SERVICE` is unset there is no protection (the db cannot be identified).

**Output convention:** command builders emit progress/success feedback with `echo` (`🚀` start, `📦` step, `✅` done) as elements of the `command` array.

## Testing conventions

Tests use Minitest directly (no Rails test helpers). Use plain Minitest
assertions — `assert`, `refute`, `assert_equal` — never Rails-only helpers like
`assert_not`, which are not defined here.

When testing `Commands`, stub `Configuration.base_path` using Minitest's `stub`:

```ruby
Configuration.stub(:base_path, "./") { Commands.reset(...) }
```

Test files mirror `lib/` structure under `test/`. The aggregator
`test/mobydock_test.rb` `require`s `minitest/autorun` and globs every
`test/mobydock/*_test.rb`, so new test files are picked up automatically.
