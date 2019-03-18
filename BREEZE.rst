..  Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at


..  http://www.apache.org/licenses/LICENSE-2.0


..  Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.


.. raw:: html

   <p align="center">
     <img src="images/AirflowBreeze_logo.png" alt="Airflow Breeze Logo"/>
   </p>


Table of Contents
=================

* `Airflow Breeze <#airflow-breeze>`_
* `Installation <#installation>`_
* `Setting up autocomplete <#setting-up-autocomplete>`_
* `Using the Airflow Breeze environment <#using-the-airflow-breeze-environment>`_
    - `Entering the environment <#entering-the-environment>`_
    - `Running tests in Airflow Breeze <#running-tests-in-airflow-breeze>`_
    - `Debugging with ipdb <#debugging-with-ipdb>`_
* `Using your host IDE <#using-your-host-ide>`_
    - `Configuring local virtualenv <#configuring-local-virtualenv>`_
    - `Running unit tests via IDE <#running-unit-tests-via-ide>`_
    - `Debugging Airflow Breeze Tests in IDE <#debugging-airflow-breeze-tests-in-ide>`_
* `Port forwarding <#port-forwarding>`_
* `Updating dependencies <#updating-dependencies>`_
* `Automating test execution <#automating-test-execution>`_
* `Running commands inside docker <#running-commands-inside-docker>`_
* `Convenience scripts <#convenience-scripts>`_
* `Airflow Breeze flags <#airflow-breeze-flags>`_

Airflow Breeze
==============

Airflow Breeze is an easy-to-use integration test environment managed via
`Docker Compose <https://docs.docker.com/compose/>`_ .
The environment is easy to use locally and it is also used by Airflow's CI Travis tests.

It's called **Airflow Breeze** as in "It's a *Breeze* to develop Airflow"

The advantages and disadvantages of using the environment vs. other ways of testing Airflow
are described in `CONTRIBUTING.md <CONTRIBUTING.md#integration-test-development-environment>`_.

Here is the short 10 minute video about Airflow Breeze

.. image:: http://img.youtube.com/vi/ffKFHV6f3PQ/0.jpg
   :width: 480px
   :height: 360px
   :scale: 100 %
   :alt: Airflow Breeze Simplified Development Workflow
   :align: center
   :target: http://www.youtube.com/watch?v=ffKFHV6f3PQ


Installation
============

Prerequisites for the installation:


* 
  If you are on MacOS you need gnu getopt to get Airflow Breeze running. Typically
  uou need to run ``brew install gnu-getopt`` and then follow instructions (you need
  to link the gnu getopt version to become first on the PATH).

* 
  Latest stable Docker Community Edition installed and on the PATH. It should be
  configured to be able to run ``docker`` commands directly and not only via root user


  * your user should be in ``docker`` group.
    See `Docker installation guide <https://docs.docker.com/install/>`_

* 
  Latest stable Docker Compose installed and on the PATH. It should be
  configured to be able to run ``docker-compose`` command.
  See `Docker compose installation guide <https://docs.docker.com/compose/install/>`_

* 
  npm locally installed in case you want to test webserver and want to test ``airflow webserver``.
  If you do not have npm, then you have to manully run ``npm install && npm run prod`` in
  airflow/www directory before you start the webserver (when sources are mounted from host)

*
  in case of MacOS you need gstat installed via brew or port. The stat command from MacOS
  is very old and poor. The best way to install it is via ``brew install coreutils``


Your entry point for Airflow Breeze is `./breeze <./breeze>`_
script. You can run it with ``-h`` option to see the list of available flags.
You can add the checked out airflow repository to your PATH to run breeze
without the ./ and from any directory if you have only one airflow directory checked out.

See `Airflow Breeze flags <#airflow-breeze-flags>`_ for details.

First time you run `./breeze <./breeze>`_ script, it will pull and build lockal version of docker images.
It will pull latest Airflow CI images from `Apache Airflow DockerHub <https://hub.docker.com/r/apache/airflow>`_
and use them to build your local docker images. It will use latest sources from your source code.
Further on ``breeze`` uses md5sum calculation and Docker caching mechanisms to only rebuild what is needed.
Airflow Breeze will detect if Docker images need to be rebuilt and ask you for confirmation.

Setting up autocomplete
=======================

The ``breeze`` command comes with built-in bash autocomplete. When you start typing
`./breeze <./breeze>`_ command you can use <TAB> to show all the available switches
nd to get autocompletion on typical values of parameters that you can use.

You can setup auto-complete automatically by running this command (-a is shortcut for --setup-autocomplete):

.. code-block:: bash

   ./breeze -a


You get autocomplete working when you re-enter the shell or run ``source ~/.bash_completion``.


Using the Airflow Breeze environment
====================================

Entering the environment
------------------------

You enter the integration test environment by running the `./breeze <./breeze>`_ script.

You can specify python version to use, backend to use and environment for testing - so that you can
recreate the same environments as we have in matrix builds in Travis CI. The defaults when you
run the environment are reasonable (python 3.6, sqlite, docker).

What happens next is the appropriate docker images are pulled, local sources are used to build local version
of the image and you are dropped into bash shell of the airflow container -
with all necessary dependencies started up. Note that the first run (per python) might take up to 10 minutes
on a fast connection to start. Subsequent runs should be much faster.

.. code-block:: bash

   ./breeze

You can choose whatever set of flags you need with `./breeze <./breeze>`_.

You could choose to run python 3.6 tests with mysql as backend and in docker
environment by:

.. code-block:: bash

   ./breeze --python 3.6 --backend mysql --env docker

The choices you made are persistent in ``./.breeze/`` cache directory so that next time when you use the
`./breeze <./breeze>`_ script it will use the values that were used previously, so you do not
have to specify them when you run the script. You can delete the ``./.breeze/`` in case you want to
restore default settings.

Relevant sources of airflow are mounted inside the ``airflow-testing`` container that you enter
so that you can continue editing your changes in the host in your favourite IDE and have them
visible in docker immediately and ready to test without rebuilding images. This can be disabled by specifying
``--skip-mounting-source-volume`` flag when running breeze, in which case you will have sources
embedded in the container - and changes to those sources will not be persistent.

Once you enter the environment you are dropped into bash shell and you can run tests immediately.

Breeze directory structure
--------------------------

When you are in the container note that following directories are used:

.. code-block:: text

  /opt/airflow - here sources of Airflow are mounted from the host
  /root/airflow - all the "dynamic" Airflow files are created here:
      airflow.db - sqlite database in case sqlite is used
      dags - folder where non-test dags are stored (test dags are in /opt/airflow/tests/dags)
      logs - logs from airflow executions are created there
      unittest.cfg - unit test configuration generated when entering the environment
      webserver_config.py - webserver configuration generated when running airflow in the container

Note that when run in your local environment ``/root/logs`` folder is actually mounted from your ``logs``
directory in airflow sources, so all logs created in the container are automatically visible in the host
as well. Every time you enter the container the logs directory is cleaned so that logs do not accumulate.


Running tests in Airflow Breeze
-------------------------------

Once you enter Airflow Breeze environment you should be able to simply run
`run-tests` at will. Note that if you want to pass extra parameters to nose
you should do it after '--'

For example, in order to just execute the "core" unit tests, run the following:

.. code-block:: bash

   run-tests tests.core:CoreTest -- -s --logging-level=DEBUG

or a single test method:

.. code-block:: bash

   run-tests tests.core:CoreTest.test_check_operators -- -s --logging-level=DEBUG


The tests will run 'airflow resetdb' and 'airflow initdb' the first time you
run tests in running container, so you can count on database being initialized.

All subsequent test executions within the same container will run without database
initialisation.

You can also optionally add --with-db-init flag if you want to re-initialize
the database.

.. code-block:: bash

   run-tests --with-db-init tests.core:CoreTest.test_check_operators -- -s --logging-level=DEBUG


Debugging with ipdb
-------------------

You can debug any code you run in the container using ``ipdb`` debugger if you prefer console debugging.
It is as easy as copy&pasting this line into your code:

.. code-block:: python

   import ipdb; ipdb.set_trace()

Once you hit the line you will be dropped into interactive ipdb  debugger where you have colors
and auto-completion to guide your debugging. This works from the console where you started your program.
Note that in case of `nosetest` you need to provide `--nocapture` flag to avoid nosetests capturing the stdout
of your process.

TODO: add image


Using your host IDE
===================

Configuring local virtualenv
----------------------------

In order to use your host IDE (for example IntelliJ's PyCharm/Idea) you need to have virtual environments
setup. Ideally you should have virtualenvs for all python versions that Airflow supports (2.7, 3.5, 3.6).
You can create the virtualenv using ``virtualenvwrapper`` - that will allow you to easily switch between
virtualenvs using workon command and mange your virtual environments more easily.

Typically creating the environment can be done by:

.. code-block:: bash

  mkvirtualenv <ENV_NAME> --python=python<VERSION>


After the virtualenv is created, you must initialize it. Simply enter the environment
(using workon) and once you are in it run:

./breeze --initialize-local-virtualenv

Once initialization is done, you should select the virtualenv you initialized as the project's default
virtualenv in your IDE.

Running unit tests via IDE
--------------------------

After setting it up - you can use the usual "Run Test" option of the IDE and have all the
autocomplete and documentation support from IDE as well as you can debug and click-through
the sources of Airflow - which is very helpful during development. Usually you also can run most
of the unit tests (those that do not require prerequisites) directly from the IDE:

Running unit tests from IDE is as simple as:

.. raw:: html

   <p align="center">
     <img src="images/running_unittests.png" alt="Running unit tests"/>
   </p>

Some of the core tests use dags defined in ``tests/dags`` folder - those tests should have
``AIRFLOW__CORE__UNIT_TEST_MODE`` set to True. You can set it up in your test configuration:

.. raw:: html

   <p align="center">
     <img src="images/airflow_unit_test_mode.png" alt="Airflow Unit test mode"/>
   </p>


You cannot run all the tests this way - only unit tests that do not require external dependencies
such as postgres/mysql/hadoop etc. You should use
`Running tests in Airflow Breeze <#running-tests-in-airflow-breeze>`_ in order to run those tests. You can
still use your IDE to debug those tests as explained in the next chapter.

Debugging Airflow Breeze Tests in IDE
-------------------------------------

When you run example DAGs - even if you run them using UnitTests from within IDE, they are run in a separate
container. This makes it a little harder to use with IDE built-in debuggers.
Fortunately for IntelliJ/PyCharm it is fairly easy using remote debugging feature (note that remote
debugging is only available in paid versions of IntelliJ/PyCharm).

You can read general description `about remote debugging
<https://www.jetbrains.com/help/pycharm/remote-debugging-with-product.html>`_

You can setup your remote debug session as follows:

.. raw:: html

   <p align="center">
     <img src="images/setup_remote_debugging.png" alt="Setup remote debugging"/>
   </p>


Not that if you are on ``MacOS`` you have to use the real IP address of your host rather than default
localhost because on MacOS container runs in a virtual machine with different IP address.

You also have to remember about configuring source code mapping in remote debugging configuration to map
your local sources into the ``/opt/airflow`` location of the sources within the container.

.. raw:: html

   <p align="center">
     <img src="images/source_code_mapping_ide.png" alt="Source code mapping"/>
   </p>


Port forwarding
===============

When you run Airflow Breeze, the following ports are automatically forwarded:


* 28080 -> forwarded to airflow webserver -> airflow-testing:8080
* 25433 -> forwarded to postgres database -> postgres:5432
* 23306 -> forwarded to mysql database  -> mysql:3306

You can connect to those ports/databases using:

* Webserver: (http://127.0.0.1:28080)[http://127.0.0.1:28080]
* Postgres: ``jdbc:postgresql://127.0.0.1:25433/airflow?user=postgres&password=airflow``
* Mysql: ``jdbc:mysql://localhost:23306/airflow?user=root``

Note that you need to start the webserver manually with ``airflow webserver`` command if you want to connect
to the webserver (you can use ``tmux`` to multiply terminals).

For databases you need to run ``airflow resetdb`` at least once after you started Airflow Breeze to get
the database/tables created. You can connect to databases with IDE or any other Database client:

.. raw:: html

   <p align="center">
     <img src="images/database_view.png" alt="Database view"/>
   </p>

You can change host port numbers used by setting appropriate environment variables:

* WEBSERVER_HOST_PORT
* POSTGRES_HOST_PORT
* MYSQL_HOST_PORT

When you set those variables, next time when you enter the environment the new ports should be in effect.


Updating dependencies
=====================

If you change apt dependencies in the Dockerfile or change setup.py or
add new apt dependencies or npm dependencies, you have two options how to update the dependencies.


*
  you can install them inside the container using 'sudo apt install', 'pip install' or 'npm install'
  (in airflow/www folder) respectively. Those changes are not persistent - they will be gone once you
  exit the container (except npm dependencies in case your sources are mounted to the container)

*
  you can rebuild the image. This should happen automatically if you modify any of setup.py, package.json or
  change Dockerfile. You need to exit the container and re-run `./breeze <./breeze>`_. Airflow Breeze will
  notice changes in dependencies, ask you to confirm rebuilding the image and will rebuild the image and
  drop you in shell. You might also provide --build-only flag to only rebuild images and not go into shell.

Note about modifying apt dependencies:

Note that changing dependencies in apt-get closer to the top of the Dockerfile will invalidate
cache for most of the image and it will take long time to rebuild the image by breeze.
Therefore it's a recommended practice to add new dependencies closer to the bottom of
Dockerfile during development (to get the new dependencies incrementally added) and only move them to the
top when you are close to finalise the PR and merge the change.

Automating test execution
=========================

If you wish to run tests only and not drop into shell, you can run them by providing
-t, --test-target flag. You can add extra nosetest flags after -- in the commandline.

.. code-block:: bash

     ./breeze --test-target tests/hooks/test_druid_hook.py -- --logging-level=DEBUG

You can run the whole test suite with special '.' test target:

.. code-block:: bash

    ./breeze --test-target .

You can also specify individual tests or group of tests:

.. code-block:: bash

    ./breeze --test-target tests.core:CoreTest

Running commands inside docker
==============================

If you wish to run other commands/executables inside of Docker environment you can do it via
-x, --execute-command flag. Note that if you want to add arguments you should specify them
together withe the command surrounded with " or ' or pass them after -- as extra arguments.

.. code-block:: bash

     ./breeze --execute-command "ls -la"

.. code-block:: bash

     ./breeze --execute-command ls -- --la

Running docker-compose commands
===============================

If you wish to run docker-compose command (such as help/pull etc. ) you can do it via
-d, --docker-compose flag. Note that if you want to add extra arguments you should specify them
after -- as extra arguments.

.. code-block:: bash

     ./breeze --docker-compose pull -- --ignore-pull-failures

Convenience scripts
===================

Once you run ./breeze you can also execute some actions via generated convenience scripts

.. code-block::

   Enter the environment          : ./breeze/cmd_run
   Run command in the environment : ./breeze/cmd_run "[command with args]" [bash options]
   Run tests in the environment   : ./breeze/test_run [test-target] [nosetest options]
   Run Docker compose command     : ./breeze/dc [help/pull/...] [docker-compose options]


If you have the airflow sources added to your path you will be able to run those
commands directly from any directory.

Breeze flags
============

Those are the current flags of the `./breeze <./breeze>`_ script

.. code-block:: text

  Usage: breeze [FLAGS] [-t <TARGET>]|[-d <COMMAND>]|[-x <COMMAND>][-x] -- <EXTRA_ARGS>

  Enters integration test environment for Airflow. It can be used to enter interactive environment (when no
  EXTRA_ARGS are specified), run test target specified (when -t, --test-target flag is used or to
  execute arbitrary command in the environment (when no test target is specified but extra args are).


  Flags:

  -h, --help
          Shows this help message.

  -P, --python <PYTHON_VERSION>
          Python version used for the image. This is always major/minor version.
          One of [ 3.5 3.6 ]. Default is the python3 or python on the path.

  -E, --env <ENVIRONME§NT>
          Environment to use for tests. It determines which types of tests can be run.
          One of [ docker kubernetes ]. Default: docker

  -B, --backend <BACKEND>
          Backend to use for tests - it determines which database is used.
          One of [ sqlite mysql postgres ]. Default: sqlite

  -K, --kubernetes-version <KUBERNETES_VERSION>
          Kubernetes version - only used in case of 'kubernetes' environment.
          One of [ v1.9.0 v1.13.0 ]. Default: v1.13.0

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


  Setting up your local environment:

  -e, --initialize-local-virtualenv
          Initializes locally created virtualenv installing all dependencies of Airflow.
          This local virtualenv can be used to aid autocompletion and IDE support as
          well as run unit tests directly from the IDE. You need to have virtualenv
          activated before running this command.

  -a, --setup-autocomplete
          Sets up autocomplete for breeze commands. Once you do it you need to re-enter the bash
          shell and when typing breeze command <TAB> will provide autocomplete for parameters and values.

  Managing of the docker compose images:

  -D, --dockerhub-user
          DockerHub user used to pull, push and build images. Default: apache.

  -H, --dockerhub-repo
          DockerHub repository used to pull, push, build images. Default: airflow.

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
