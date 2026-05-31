#

![Mobydock][logo-mobydock]

Make easier personal dockerized projects. It allows to handle several environment (development, integration, production) having a `docker-compose` file for each environment configured and adding an extra sweet shortcuts to make life easier using `docker-compose`.

## Prerrequisites

* Have installed Docker. Otherwise just check [here](https://docs.docker.com/v17.09/engine/installation/).

* Have installed `docker-compose`. Otherwise just check [here](https://docs.docker.com/compose/install/).

* Optionally you can have installed `docker-machine`. Otherwise just check [here](https://docs.docker.com/machine/install-machine/).

* Have installed Ruby ~> 2.7. Otherwise just check some examples of Ruby version managers depending on your operating system:

  * [Homebrew](https://brew.sh/) for MAC.
  * [Linuxbrew](http://linuxbrew.sh/) for Linux.
  * [Scoop](http://scoop.sh/)for windows. More info in [https://github.com/lukesampson/scoop](https://github.com/lukesampson/scoop)

## How to install

First of all you need to clone the project to your computer:

```sh
git clone https://github.com/lmbautista/mobydock.git
```

Specify the path where your dockerized proyect is located:

```sh
export MOBYDOCK_PATH="/Users/Projects/my_docker_project"
```

Specify the available environments you need:

```sh
export MOBYDOCK_ENVS="development,integration,production"
```

Name your `docker-compose` files with those available environments:

```plain
/Users/Projects/my_docker_project
|__ docker-compose-development.yml
|__ docker-compose-integration.yml
|__ docker-compose-production.yml
```

Add the bin dir into your `$PATH` replacing `mobydock_dir` by the path where your cloned `Mobydock`:

```sh
 export PATH=$PATH:mobydock_dir/bin
```

## How it works

Mobydock is just an extra layer to work of `docker-compose` which try to add some sweet shortcuts to make life easier. There are some of the ways to use it:

```sh
# It execute docker-compose commands for your development environment

mobydock [environment] up -d
mobydock [environment] exec -it [service] bash
```

## Sweet shortcuts

```sh
# It execute docker-compose run command to execute a bin/setup script file for your service defined in your development environment

mobydock [environment] setup [service]
```

```sh
# It stops, removes, builds and runs or all services or a specific one.

mobydock [environment] reset [service]
```

```sh

# In case you have images in your DockerHub this command allows you to refresh that image locally and regenerate the container or the target service

mobydock [environment] update [service] [image]
```

```sh
# Dump the MySQL database to backups/ and restore it back from a dump file

mobydock [environment] backup-db
mobydock [environment] restore-db backups/backup-production-20260531-120000.sql
```

```sh
# List the docker-machines, and remove the one for an environment
# (destroy terminates the remote instance, so it requires --force)

mobydock ls
mobydock [environment] destroy --force
```

## Show the active environment in your prompt

Just like the git branch is shown in the prompt, you can show the mobydock
environment you are working against. The environment is set when you activate a
remote `docker-machine` with `login`, which exports `MOBYDOCK_ENV` into your
shell:

```sh
eval $(mobydock production login)    # now MOBYDOCK_ENV=production
eval $(mobydock production logout)   # disconnects and clears MOBYDOCK_ENV
```

To render it in your prompt, source the provided snippet and add the segment:

```sh
# ~/.zshrc
source mobydock_dir/shell/mobydock-prompt.sh
setopt PROMPT_SUBST
PROMPT='$(mobydock_prompt)'$PROMPT
```

```sh
# ~/.bashrc
source mobydock_dir/shell/mobydock-prompt.sh
PROMPT_COMMAND='__mobydock_ps1=$(mobydock_prompt)'"${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
PS1='${__mobydock_ps1}'$PS1
```

Your prompt will then show `(mobydock:production)` while that environment is
active. Run `eval $(mobydock production logout)` (or `unset MOBYDOCK_ENV`) to
clear it.

## Protecting the database on sensitive environments

Destructive operations against the database container can be blocked on the
environments you consider sensitive (e.g. staging and production). List them in
`MOBYDOCK_PROTECTED_ENVS` and tell mobydock which service is the database with
`MOBYDOCK_DB_SERVICE`:

```sh
export MOBYDOCK_PROTECTED_ENVS="staging,production"
export MOBYDOCK_DB_SERVICE="db"
```

With that in place, commands that would stop, remove, recreate or restore the
database service on a protected environment (`reset`, `update`, `update-all`,
`restore-db`, and the `down`/`rm`/`stop`/`kill` passthroughs) are refused:

```sh
mobydock production reset db
# 🛡️  Database protection: this operation would affect the 'production' database...
```

Re-run the exact same command with `--force` when you really mean it:

```sh
mobydock production reset db --force
```

[logo-mobydock]: https://user-images.githubusercontent.com/6224703/99860828-90d58a80-2b94-11eb-8a9f-aa5171bc4ad9.png "Mobydock"
