<!--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->

<p align="center">
  <img src="images/AirflowBreeze_logo.png" alt="Airflow Breeze Logo"/>
</p>

# Table of Contents

  * [Airflow Breeze](#airflow-breeze)
  * [Installation](#installation)
  * [Entering the environment](#entering-the-environment)
  * [Updating dependencies](#updating-dependencies)
  * [Forwarded ports](#forwarded-ports)
  * [Running tests](#running-tests)
  * [Automating test execution](#automating-test-execution)
  * [Running commands inside docker](#running-commands-inside-docker)
  * [Convenience scripts](#convenience-scripts)
  * [Breeze flags](#breeze-flags)

# Airflow Breeze

Airflow has an easy-to-use integration test environment managed via
[Docker Compose](https://docs.docker.com/compose/) and used by Airflow's CI Travis tests.

It's called **Airflow Breeze** as in "It's a breeze to develop with Airflow"

The advantages and disadvantages of using the environment vs. other ways of testing Airflow
are described in [CONTRIBUTING.md](CONTRIBUTING.md#integration-test-development-environment).

# Installation

Prerequisites for the installation:

* If you are on MacOS you need gnu getopt to get Airflow Breeze running. Typically
  uou need to run `brew install gnu-getopt` and then follow instructions (you need
  to link the gnu getopt version to become first on the PATH).

* Latest stable Docker Community Edition installed and on the PATH. It should be
  configured to be able to run `docker` commands directly and not only via root user
  - your user should be in `docker` group.
  See [Docker installation guide](https://docs.docker.com/install/)

* Latest stable Docker Compose installed and on the PATH. It should be
  configured to be able to run `docker-compose` command.
  See [Docker compose installation guide](https://docs.docker.com/compose/install/)

* npm locally installed in case you want to test webserver and want to test `airflow webserver`.
  If you do not have npm, then you have to manully run `npm install && npm run prod` in
  airflow/www directory before you start the webserver (when sources are mounted from host)

Your entry point for integration test environment is [./breeze](./breeze)
script. You can run it with -h option to see the list of available flags.
You can add the airflow repository to your PATH to run breeze without the ./ in front and from any
directory.


See [Breeze flags](#breeze-flags) for details.

First time you run [./breeze](./breeze) script - it will prepare docker images.
It will pull latest Airflow CI images from [Apache Airflow DockerHub](https://hub.docker.com/r/apache/airflow)
and use them to build your local docker images - including latest sources from your source code.
It uses md5sum calculation and Docker caching mechanisms to only rebuild what's needed.
Airflow Breeze will detect if Docker images need to be rebuilt and ask for confirmation then.


# Entering the environment

You enter the integration test environment by running the [./breeze](./breeze) script.

You can specify python version to use, backend to use and environment for testing - so that you can
recreate the same environments as we have in matrix builds in Travis CI. The defaults when you
run the environment are reasonable (python 3.6, sqlite, docker) but you can choose whatever set
of flags you need using flags of [./breeze](./breeze).

You could choose to run python 3.6 tests with mysql as backend and in docker
environment by:

```bash
./breeze --python 3.6 --backend mysql --env docker
```

The choices you made are persisted in ./.breeze_* files so that next time when you use the
[./breeze](./breeze) script it will select the values that were used
last time so you do not have to specify them when you run the script.

By default sources of airflow are mounted inside the `airflow-testing` container that you enter
so that you can continue editing your changes in the host in your favourite IDE and have them
visible in docker immediately and ready to test without rebuilding images. This can be disabled by specifying
`--skip-mounting-source-volume` flag when running breeze, in which case you will have sources
embedded in the container - and changes to those sources will not be persistent.

Once you enter the environment you are dropped into bash shell - you can then run tests as described below.

# Updating dependencies

If you change apt dependencies in the Dockerfile or change setup.py or
add new apt dependencies or npm dependencies, you have two options how to update the dependencies.

* you can install them inside the container using 'sudo apt install', 'pip install' or 'npm install'
  (in airflow/www folder) respectively. Those changes are not persistent - they will be gone once you
  exit the container (except npm dependencies in case your sources are mounted to the container)

* you can rebuild the image. This should happen automatically if you modify any of setup.py, package.json or
  change Dockerfile. You need to exit the container and re-run [./breeze](./breeze). Breeze will notice
  changes in dependencies, ask you to confirm rebuilding the image and will rebuild the image and drop you
  in shell. You might also provide --build-only flag to only rebuild images and not drop into shell.

Npte about modifying apt dependencies:

Note that changing dependencies in apt-get closer to the top of the Dockerfile will invalidate
cache for most of the image and it will take long time to rebuild the image by breeze.
Therefore it's a recommended practice to add new dependencies closer to the bottom of
Dockerfile during development (to get the new dependencies incrementally added) and only move them to the
top when you are close to finalise the PR and merge the change.

# Forwarded ports


When you run breeze, the following ports are automatically forwarded:

* 28080 -> forwarded to airflow webserver -> airflow-testing:8080
* 25433 -> forwarded to postgres database -> postgres:5432
* 23306 -> forwarded to mysql database  -> mysql:3306

You can connect to those ports/databases using:

* Webserver: (http://127.0.0.1:28080)[http://127.0.0.1:28080]

* Postgres: `jdbc:postgresql://127.0.0.1:25433/airflow?user=postgres&password=airflow`

* Mysql: `jdbc:mysql://localhost:23306/airflow?user=root`

Note that you need to start the webserver manually with `airflow webserver` command if you want to connect
to the webserver (you can use tmux to multiply terminals).

For databases you need to run `airflow resetdb` at least once after you started Airflow Breeze to get
the database/tables created.

You can change host port numbers used by setting appropriate environment variables:
* WEBSERVER_HOST_PORT
* POSTGRES_HOST_PORT
* MYSQL_HOST_PORT

When you set those variables, next time when you enter the environment the ports should be changed.

# Running tests

Once you enter integration test environment you should be able to simply run
``./run_tests.sh`` at will.

For example, in order to just execute the "core" unit tests, run the following:

```bash
./run_tests.sh tests.core:CoreTest -s --logging-level=DEBUG
```
or a single test method:

```bash
./run_tests.sh tests.core:CoreTest.test_check_operators -s --logging-level=DEBUG
```

# Automating test execution

If you wish to run tests only and not drop into shell, you can run them by providing
-t, --test-target flag. You can add extra nosetest flags after -- in the commandline.

```bash
  ./breeze --test-target tests/hooks/test_druid_hook.py -- --logging-level=DEBUG
```

You can run the whole test suite with special '.' test target:

```bash
 ./breeze --test-target .
```

You can also specify individual tests or group of tests:

```bash
 ./breeze --test-target tests.core:CoreTest
```

# Running commands inside docker

If you wish to run other commands/executables inside of Docker environment you can do it via
-x, --execute-command flag. Note that if you want to add arguments you should specify them
together withe the command surrounded with " or ' or pass them after -- as extra arguments.

```bash
  ./breeze --execute-command "ls -la"
```

```bash
  ./breeze --execute-command ls -- --la
```

# Running docker-compose commands

If you wish to run docker-compose command (such as help/pull etc. ) you can do it via
-d, --docker-compose flag. Note that if you want to add extra arguments you should specify them
after -- as extra arguments.

```bash
  ./breeze --docker-compose pull -- --ignore-pull-failures
```

# Convenience scripts

Once you run ./breeze you can also execute some actions via generated convenience scripts

    Enter the environment          : ./breeze_cmd_run
    Run command in the environment : ./breeze_cmd_run "[command with args]" [bash options]
    Run tests in the environment   : ./breeze_test_run [test-target] [nosetest options]
    Run Docker compose command     : ./breeze_dc [help/pull/...] [docker-compose options]

If you have the airflow sources added to your path you will be able to run those
commands directly from any directory.

# Breeze flags

Those are the current flags of the [./breeze](./breeze) script

```text
Usage: breeze [FLAGS] [-t <TARGET>]|[-d <COMMAND>]|[-x <COMMAND>][-x] -- <EXTRA_ARGS>

Enters integration test environment for Airflow. It can be used to enter interactive environment (when no
EXTRA_ARGS are specified), run test target specified (when -t, --test-target flag is used or to
execute arbitrary command in the environment (when no test target is specified but extra args are).


Flags:

-h, --help
        Shows this help message.

-P, --python <PYTHON_VERSION>
        Python virtualenv used. One of ('2.7', '3.5', '3.6'). [3.6]

-E, --env <ENVIRONMENT>
        Environment to use for tests. One of ('docker' or 'kubernetes') [docker]

-B, --backend <BACKEND>
        Backend to use for tests. One of ('sqlite', 'mysql', 'postgres') [sqlite]

-K, --kubernetes-version <KUBERNETES_VERSION>
        Version of kubernetes to use ('v1.9.0', 'v1.13.0') [v1.13.0]

-s, --skip-mounting-source-volume
        Skips mounting local volume with sources - you get exactly what is in the
        docker image rather than your current local sources of airflow.

-b, --build-only
        Only build docker images but do not enter the airflow-testing docker container.

-v, --verbose
        Show verbose information about executed commands (enabled by default for running test)

-y, --assume-yes
        Assume 'yes' answer to all questions.

-C, --toggle-suppress-cheatsheet
        Toggles on/off cheatsheet displayed before starting bash shell

-A, --toggle-suppress-asciiart
        Toggles on/off asciiart displayed before starting bash shell


Initializing your local virtualenv:

-e, --initialize-local-virtualenv
        Initializes locally created virtualenv installing all dependencies of Airflow.
        This local virtualenv can be used to aid autocompletion and IDE support as
        well as run unit tests directly from the IDE. You need to have virtualenv
        activated before running this command.

Managing of the docker compose images:

-D, --dockerhub-user
        DockerHub user used to pull, push and build images [airflow].

-r, --force-rebuild-images
        Forces rebuilding of the local docker images. The images are rebuilt
        automatically for the first time or when changes are detected in
        package-related files, but you can force it using this flag.

-R, --force-rebuild-clean-images
        Force rebuild images without cache. This will remove the pulled or build images
        and start building images from scratch. This might take a long time.

-p, --force-pull-images
        Forces pulling of images from DockerHub before building to populate cache. The
        images are pulled by default only for the first time you run the
        environment, later the locally build images are used as cache.

-u, --push-images
        After rebuilding - uploads the images to DockerHub
        It is useful in case you use your own DockerHub user to store images and you want
        to build them locally. Note that you need to use 'docker login' before you upload images.

-c, --cleanup-images
        Cleanup your local docker cache of the airflow docker images. This will not reclaim space in
        docker cache. You need to 'docker system prune' to actually reclaim that space.


By default the script enters IT environment and drops you to bash shell,
but you can also choose one of the commands to run specific actions instead:


-t, --test-target <TARGET>
        Run the specified unit test target. There might be multiple
        targets specified separated with comas. The <EXTRA_ARGS> passed after -- are treated
        as additional options passed to nosetest. For example

        './breeze --test-target tests.core -- --logging-level=DEBUG'

-x, --execute-command <COMMAND>
        Run chosen command instead of entering the environment. The command is run using
        'bash -c "<command with args>" if you need to pass arguments to your command, you need
        to pass them together with command surrounded with " or '. Alternatively you can pass arguments as
         <EXTRA_ARGS> passed after --. For example

        './breeze --execute-command "ls -la"' or
        './breeze --execute-command ls -- --la'

-d, --docker-compose <COMMAND>
        Run docker-compose command instead of entering the environment. Use 'help' command
        to see available commands. The <EXTRA_ARGS> passed after -- are treated
        as additional options passed to docker-compose. For example

        './breeze --docker-compose pull -- --ignore-pull-failures'

Killing docker compose.

-k, --docker-compose-down
        Bring down running docker compose. When you start the environment, the docker containers will
        continue running so that startup time is shorter. This command stops all running containers.
        It is equivalent to running '---docker-compose down'

```
