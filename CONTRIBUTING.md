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

# Contributing

Contributions are welcome and are greatly appreciated! Every
little bit helps, and credit will always be given.

# Table of Contents
  * [TOC](#table-of-contents)
  * [Types of Contributions](#types-of-contributions)
      - [Report Bugs](#report-bugs)
      - [Fix Bugs](#fix-bugs)
      - [Implement Features](#implement-features)
      - [Improve Documentation](#improve-documentation)
      - [Submit Feedback](#submit-feedback)
  * [Documentation](#documentation)
  * [Development and Testing](#development-and-testing)
      - [Setting up a development environment](#setting-up-a-development-environment)
      - [Running unit tests](#running-unit-tests)
  * [Pull requests guidelines](#pull-request-guidelines)
  * [Changing the Metadata Database](#changing-the-metadata-database)

## Types of Contributions

### Report Bugs

Report bugs through [Apache Jira](https://issues.apache.org/jira/browse/AIRFLOW)

Please report relevant information and preferably code that exhibits
the problem.

### Fix Bugs

Look through the Jira issues for bugs. Anything is open to whoever wants
to implement it.

### Implement Features

Look through the [Apache Jira](https://issues.apache.org/jira/browse/AIRFLOW) for features. Any unassigned "Improvement" issue is open to whoever wants to implement it.

We've created the operators, hooks, macros and executors we needed, but we
made sure that this part of Airflow is extensible. New operators,
hooks, macros and executors are very welcomed!

### Improve Documentation

Airflow could always use better documentation,
whether as part of the official Airflow docs,
in docstrings, `docs/*.rst` or even on the web as blog posts or
articles.

### Submit Feedback

The best way to send feedback is to open an issue on [Apache Jira](https://issues.apache.org/jira/browse/AIRFLOW)

If you are proposing a feature:

- Explain in detail how it would work.
- Keep the scope as narrow as possible, to make it easier to implement.
- Remember that this is a volunteer-driven project, and that contributions are welcome :)

## Documentation

The latest API documentation is usually available
[here](https://airflow.apache.org/). To generate a local version,
you need to have set up an Airflow development environment (see below). Also
install the `doc` extra.

```
pip install -e '.[doc]'
```

Generate and serve the documentation by running:

```
cd docs
./build.sh
./start_doc_server.sh
```

Only a subset of the API reference documentation builds. Install additional
extras to build the full API reference.

## Development and Testing

### Setting up a development environment

There are three ways to setup an Apache Airflow development environment.

1. Using tools and libraries installed directly on your system

  Install Python (2.7.x or 3.5.x), MySQL, and libxml by using system-level package
  managers like yum, apt-get for Linux, or Homebrew for Mac OS at first. Refer to the [base CI Dockerfile](https://github.com/apache/airflow-ci/blob/master/Dockerfile) for
  a comprehensive list of required packages.

  Then install python development requirements. It is usually best to work in a virtualenv:

  ```bash
  cd $AIRFLOW_HOME
  virtualenv env
  source env/bin/activate
  pip install -e '.[devel]'
  ```

2. Using a Docker container

  Go to your Airflow directory and start a new docker container. You can choose between Python 2 or 3, whatever you prefer.

  ```
  # Start docker in your Airflow directory
  docker run -t -i -v `pwd`:/airflow/ -w /airflow/ python:3 bash

  # To install all of airflows dependencies to run all tests (this is a lot)
  pip install -e .

  # To run only certain tests install the devel requirements and whatever is required
  # for your test.  See setup.py for the possible requirements. For example:
  pip install -e '.[gcp,devel]'

  # Init the database
  airflow initdb

  nosetests -v tests/hooks/test_druid_hook.py

    test_get_first_record (tests.hooks.test_druid_hook.TestDruidDbApiHook) ... ok
    test_get_records (tests.hooks.test_druid_hook.TestDruidDbApiHook) ... ok
    test_get_uri (tests.hooks.test_druid_hook.TestDruidDbApiHook) ... ok
    test_get_conn_url (tests.hooks.test_druid_hook.TestDruidHook) ... ok
    test_submit_gone_wrong (tests.hooks.test_druid_hook.TestDruidHook) ... ok
    test_submit_ok (tests.hooks.test_druid_hook.TestDruidHook) ... ok
    test_submit_timeout (tests.hooks.test_druid_hook.TestDruidHook) ... ok
    test_submit_unknown_response (tests.hooks.test_druid_hook.TestDruidHook) ... ok

    ----------------------------------------------------------------------
    Ran 8 tests in 3.036s

    OK
  ```

  The Airflow code is mounted inside of the Docker container, so if you change something using your favorite IDE, you can directly test it in the container.

3. Using [Docker Compose](https://docs.docker.com/compose/) and Airflow's CI scripts

  Start a docker container through Compose for development to avoid installing the packages directly
  on your system. The following will start all required service containers
  (MySQL, PostgresSQL, krb5 and so on) and will download latest airflow container.
  Setting up Docker-compose is automated by
  [./scripts/ci/ci_run_airflow_testing.sh](./scripts/ci/ci_run_airflow_testing.sh).

  In order to use the scripts, you need to provide appropriate environment variables to choose the right
  backend and environment (see [.travis.yml](.travis.yml) for environment variable combinations that
  can be used:

  The following will start all the containers and start full test suite for Airflow for mysql:

  ```bash
  BACKEND=mysql ENV=docker ./scripts/ci/ci_run_airflow_testing.sh
  ```

  You can also chose to skip running tests and enter bash shell within the airflow container:

  ```bash
  RUN_TESTS=false BACKEND=mysql ENV=docker ./scripts/ci/ci_run_airflow_testing.sh
  ```

  When you are in the container note that following directories are used:

  ```
  /opt/airflow - here sources of Airflow are mounted from the host
  /root/airflow - all the "dynamic" Airflow files are created here:
      airflow.db - sqlite database in case sqlite is used
      dags - folder where non-test dags are stored (test dags are in /opt/airflow/tests/dags)
      logs - logs from airflow executions are created there
      unittest.cfg - unit test configuration generated when entering the environment
      webserver_config.py - webserver configuration generated when running airflow in the container
  ```

  Note that when run in your local environment `/root/logs` folder is actually mounted from your `logs`
  directory in airflow sources, so all logs created in the container are automatically visible in the host
  as well. Every time you enter the container the logs directory is cleaned so that logs do not accumulate.

  Once in the container you can use `./scripts/ci/in_container/run_ci_tests.sh` script to run tests manually.
  You can specify tests module, class or method following nosetest syntax:

  ```
  <module>[:<Test_Case>.[<test_method>]]
  ```
  If you do not provide the extra args - the script will run all the tests.

  You can also specify extra args that will be passed to nosetests. For example:

  ```
  ./scripts/ci/in_container/run_ci_tests.sh tests.core:CoreTest -s --logging-level=DEBUG
  ```

  or a single test method:

  ```
  ./run_unit_tests.sh tests.core:CoreTest.test_check_operators -s --logging-level=DEBUG
  ```

Alternatively, you can also set up [Travis CI](https://travis-ci.org/) on your repo to automate this.
It is free for open source projects.

### Running linting locally

We have a number of lint checks that are run in Travis CI but you can run them locally as well. All the
scripts are available in [scripts/ci](scripts/ci/) folder.

* [ci_check_license.sh](scripts/ci/ci_check_license.sh) - checks if all licences are present in source files.
  This script requires java and runs in host environment - this means that the check can behave differently
  on your machine than in the Travis CI.

The checks below are run in a docker environment, which means that if you run them locally, they should
give the same results as the tests run in TravisCI:

* [ci_docs.sh](scripts/ci/ci_docs.sh) - checks that documentation can be built without warnings.
  Documentation is available in [docs/_build/html](docs/_build/html) folder after the script is run
  and succeeds.
* [ci_flake8.sh](scripts/ci/ci_flake8.sh) - runs flake8 source code style guide enforcement tool
* [ci_mypy.sh](scripts/ci/ci_mypy.sh) - runs mypy type annotation consistency check
* [ci_pylint.sh](scripts/ci/ci_pylint.sh) - runs pylint static code checker
* [ci_lint_dockerfile.sh](scripts/ci/ci_lint_dockerfile.sh) - runs lint checker for the Dockerfile

### Pylint checks - work in-progress

Note that for pylint we are in the process of fixing pylint code checks for the whole Airflow code. This is
a huge task so we implemented an incremental approach for the process. Currently most of the code is
excluded from pylint checks via [pylint_todo.txt](scripts/ci/pylint_todo.txt). We have an open JIRA
issue [AIRFLOW-4364](https://issues.apache.org/jira/browse/AIRFLOW-4364) in JIRA which has a number of
JIRA sub-tasks for each of the modules that should be made compatible. Fixing pylint problems is one of
straightforward and easy tasks to do (but time-consuming) so if you are a first-time contributor to
Airflow you can choose one of the sub-tasks as your first issue to fix. The process to fix the issue looks
as follows:

1) Remove module/modules from the [pylint_todo.txt](scripts/ci/pylint_todo.txt)
2) Run [ci_pylint.sh](scripts/ci/ci_pylint.sh)
3) Fix all the issues reported by pylint
4) Re-run [ci_pylint.sh](scripts/ci/ci_pylint.sh)
5) If you see "success" - submit PR following [Pull Request guidelines](#pull-request-guidelines)

There are following guidelines when fixing pylint errors:

* Ideally fix the errors rather than disable pylint checks - often you can easily refactor the code
  (IntelliJ/PyCharm might be helpful when extracting methods in complex code or moving methods around)
* When disabling particular problem - make sure to disable only that error-via the symbolic name
  of the error as reported by pylint
* If there is a single line where to disable particular error you can add comment following the line
  that causes the problem. For example:
```python
def MakeSummary(pcoll, metric_fn, metric_keys):  # pylint: disable=invalid-name
```
* When there are multiple lines/block of code to disable an error you can surround the block with
  comment only pylint:disable/pylint:enable lines. For example:

```python
# pylint: disable=too-few-public-methods
class LoginForm(Form):
    """Form for the user"""
    username = StringField('Username', [InputRequired()])
    password = PasswordField('Password', [InputRequired()])
# pylint: enable=too-few-public-methods
```

### Git hooks

Another great way of automating linting and testing is to use
[Git Hooks](https://git-scm.com/book/uz/v2/Customizing-Git-Git-Hooks). For example you could create a
`pre-commit` file based on the Travis CI Pipeline so that before each commit a local pipeline will be
triggered and if this pipeline fails (returns an exit code other than `0`) the commit does not come through.
This "in theory" has the advantage that you can not commit any code that fails that again reduces the errors
in the Travis CI Pipelines.

Since there are a lot of tests the script would last very long so you probably only should test your new
feature locally.

The following example of a `pre-commit` file allows you..
- to lint your code via flake8
- to test your code via nosetests in a docker container based on python 2
- to test your code via nosetests in a docker container based on python 3

```
#!/bin/sh

GREEN='\033[0;32m'
NO_COLOR='\033[0m'

setup_python_env() {
    local venv_path=${1}

    echo -e "${GREEN}Activating python virtual environment ${venv_path}..${NO_COLOR}"
    source ${venv_path}
}
run_linting() {
    local project_dir=$(git rev-parse --show-toplevel)

    echo -e "${GREEN}Running flake8 over directory ${project_dir}..${NO_COLOR}"
    flake8 ${project_dir}
}
run_testing_in_docker() {
    local feature_path=${1}
    local airflow_py2_container=${2}
    local airflow_py3_container=${3}

    echo -e "${GREEN}Running tests in ${feature_path} in airflow python 2 docker container..${NO_COLOR}"
    docker exec -i -w /airflow/ ${airflow_py2_container} nosetests -v ${feature_path}
    echo -e "${GREEN}Running tests in ${feature_path} in airflow python 3 docker container..${NO_COLOR}"
    docker exec -i -w /airflow/ ${airflow_py3_container} nosetests -v ${feature_path}
}

set -e
# NOTE: Before running this make sure you have set the function arguments correctly.
setup_python_env /Users/feluelle/venv/bin/activate
run_linting
run_testing_in_docker tests/contrib/hooks/test_imap_hook.py dazzling_chatterjee quirky_stallman

```

For more information on how to run a subset of the tests, take a look at the
nosetests docs.

See also the list of test classes and methods in `tests/core.py`.

Feel free to customize based on the extras available in [setup.py](./setup.py)

## Pull Request Guidelines

Before you submit a pull request from your forked repo, check that it
meets these guidelines:

1. The pull request should include tests, either as doctests, unit tests, or both. The airflow repo uses [Travis CI](https://travis-ci.org/apache/airflow) to run the tests and [codecov](https://codecov.io/gh/apache/airflow) to track coverage. You can set up both for free on your fork (see the "Testing on Travis CI" section below). It will help you making sure you do not break the build with your PR and that you help increase coverage.
1. Please [rebase your fork](http://stackoverflow.com/a/7244456/1110993), squash commits, and resolve all conflicts.
1. Every pull request should have an associated [JIRA](https://issues.apache.org/jira/browse/AIRFLOW/?selectedTab=com.atlassian.jira.jira-projects-plugin:summary-panel). The JIRA link should also be contained in the PR description.
1. Preface your commit's subject & PR's title with **[AIRFLOW-XXX]** where *XXX* is the JIRA number. We compose release notes (i.e. for Airflow releases) from all commit titles in a release. By placing the JIRA number in the commit title and hence in the release notes, Airflow users can look into JIRA and GitHub PRs for more details about a particular change.
1. Add an [Apache License](http://www.apache.org/legal/src-headers.html) header to all new files
1. If the pull request adds functionality, the docs should be updated as part of the same PR. Doc string are often sufficient.  Make sure to follow the Sphinx compatible standards.
1. The pull request should work for Python 2.7 and 3.5. If you need help writing code that works in both Python 2 and 3, see the documentation at the [Python-Future project](http://python-future.org) (the future package is an Airflow requirement and should be used where possible).
1. As Airflow grows as a project, we try to enforce a more consistent style and try to follow the Python community guidelines. We currently enforce most [PEP8](https://www.python.org/dev/peps/pep-0008/) and a few other linting rules. It is usually a good idea to lint locally as well using [flake8](https://flake8.readthedocs.org/en/latest/) using `flake8 airflow tests`. `git diff upstream/master -u -- "*.py" | flake8 --diff` will return any changed files in your branch that require linting.
1. We also apply [Pylint](https://www.pylint.org) for linting (static code analysis). Run locally with `./scripts/ci/ci_pylint.sh`.
1. Please read this excellent [article](http://chris.beams.io/posts/git-commit/) on commit messages and adhere to them. It makes the lives of those who come after you a lot easier.

### Testing on Travis CI

We currently rely heavily on Travis CI for running the full Airflow test suite
as running all of the tests locally requires significant setup.  You can setup
Travis CI in your fork of Airflow by following the
[Travis CI Getting Started guide][travis-ci-getting-started].

There are two different options available for running Travis CI which are
setup as separate components on GitHub:

1. **Travis CI GitHub App** (new version)
1. **Travis CI GitHub Services** (legacy version)

#### Travis CI GitHub App (new version)

1. Once installed, you can configure the Travis CI GitHub App at
https://github.com/settings/installations -> Configure Travis CI.

1. For the Travis CI GitHub App, you can set repository access to either "All
repositories" for convenience, or "Only select repositories" and choose
`<username>/airflow` in the dropdown.

1. You can access Travis CI for your fork at
`https://travis-ci.com/<username>/airflow`.

#### Travis CI GitHub Services (legacy version)

The Travis CI GitHub Services versions uses an Authorized OAuth App.  Note
that `apache/airflow` is currently still using the legacy version.

1. Once installed, you can configure the Travis CI Authorized OAuth App at
https://github.com/settings/connections/applications/88c5b97de2dbfc50f3ac.

1. If you are a GitHub admin, click the "Grant" button next to your
organization; otherwise, click the "Request" button.

1. For the Travis CI Authorized OAuth App, you may have to grant access to the
forked `<organization>/airflow` repo even though it is public.

1. You can access Travis CI for your fork at
`https://travis-ci.org/<organization>/airflow`.

#### Prefer travis-ci.com over travis-ci.org

The travis-ci.org site for open source projects is now legacy and new projects
should instead be created on travis-ci.com for both private repos and open
source.

Note that there is a second Authorized OAuth App available called "Travis CI
for Open Source" used for the
[legacy travis-ci.org service][travis-ci-org-vs-com].  It should not be used
for new projects.

More information:

- [Open Source on travis-ci.com][travis-ci-open-source]
- [Legacy GitHub Services to GitHub Apps Migration Guide][travis-ci-migrating]
- [Migrating Multiple Repositories to GitHub Apps Guide][travis-ci-migrating-2]

[travis-ci-getting-started]: https://docs.travis-ci.com/user/getting-started/
[travis-ci-migrating-2]: https://docs.travis-ci.com/user/travis-migrate-to-apps-gem-guide/
[travis-ci-migrating]: https://docs.travis-ci.com/user/legacy-services-to-github-apps-migration-guide/
[travis-ci-open-source]: https://docs.travis-ci.com/user/open-source-on-travis-ci-com/
[travis-ci-org-vs-com]: https://devops.stackexchange.com/a/4305/8830


### Changing the Metadata Database

When developing features the need may arise to persist information to the the
metadata database. Airflow has [Alembic](https://bitbucket.org/zzzeek/alembic)
built-in to handle all schema changes. Alembic must be installed on your
development machine before continuing.

```
# starting at the root of the project
$ pwd
~/airflow
# change to the airflow directory
$ cd airflow
$ alembic revision -m "add new field to db"
  Generating
~/airflow/airflow/migrations/versions/12341123_add_new_field_to_db.py
```

## Setting up the node / npm javascript environment

`airflow/www/` contains all npm-managed, front end assets.
Flask-Appbuilder itself comes bundled with jQuery and bootstrap.
While these may be phased out over time, these packages are currently not
managed with npm.

### Node/npm versions

Make sure you are using recent versions of node and npm. No problems have been found with node>=8.11.3 and npm>=6.1.3

### Using npm to generate bundled files

#### npm

First, npm must be available in your environment. If it is not you can run the following commands
(taken from [this source](https://gist.github.com/DanHerbert/9520689))

```
brew install node --without-npm
echo prefix=~/.npm-packages >> ~/.npmrc
curl -L https://www.npmjs.com/install.sh | sh
```

The final step is to add `~/.npm-packages/bin` to your `PATH` so commands you install globally are usable.
Add something like this to your `.bashrc` file, then `source ~/.bashrc` to reflect the change.

```
export PATH="$HOME/.npm-packages/bin:$PATH"
```

#### npm packages

To install third party libraries defined in `package.json`, run the
following within the `airflow/www/` directory which will install them in a
new `node_modules/` folder within `www/`.

```bash
# from the root of the repository, move to where our JS package.json lives
cd airflow/www/
# run npm install to fetch all the dependencies
npm install
```

To parse and generate bundled files for airflow, run either of the
following commands. The `dev` flag will keep the npm script running and
re-run it upon any changes within the assets directory.

```
# Compiles the production / optimized js & css
npm run prod

# Start a web server that manages and updates your assets as you modify them
npm run dev
```

#### Upgrading npm packages

Should you add or upgrade a npm package, which involves changing `package.json`, you'll need to re-run `npm install`
and push the newly generated `package-lock.json` file so we get the reproducible build.

#### Javascript Style Guide

We try to enforce a more consistent style and try to follow the JS community guidelines.
Once you add or modify any javascript code in the project, please make sure it follows the guidelines
defined in [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript).
Apache Airflow uses [ESLint](https://eslint.org/) as a tool for identifying and reporting on patterns in JavaScript,
which can be used by running any of the following commands.

```bash
# Check JS code in .js and .html files, and report any errors/warnings
npm run lint

# Check JS code in .js and .html files, report any errors/warnings and fix them if possible
npm run lint:fix
```
