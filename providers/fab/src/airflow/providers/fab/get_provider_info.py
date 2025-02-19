# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# NOTE! THIS FILE IS AUTOMATICALLY GENERATED AND WILL BE OVERWRITTEN!
#
# IF YOU WANT TO MODIFY THIS FILE, YOU SHOULD MODIFY THE TEMPLATE
# `get_provider_info_TEMPLATE.py.jinja2` IN the `dev/breeze/src/airflow_breeze/templates` DIRECTORY


def get_provider_info():
    return {
        "package-name": "apache-airflow-providers-fab",
        "name": "Fab",
        "description": "`Flask App Builder <https://flask-appbuilder.readthedocs.io/>`__\n",
        "state": "ready",
        "source-date-epoch": 1731570160,
        "versions": [
            "2.0.0",
            "1.5.2",
            "1.5.1",
            "1.5.0",
            "1.4.1",
            "1.4.0",
            "1.3.0",
            "1.2.2",
            "1.2.1",
            "1.2.0",
            "1.1.1",
            "1.1.0",
            "1.0.4",
            "1.0.3",
            "1.0.2",
            "1.0.1",
            "1.0.0",
        ],
        "excluded-python-versions": ["3.13"],
        "config": {
            "fab": {
                "description": "This section contains configs specific to FAB provider.",
                "options": {
                    "auth_rate_limited": {
                        "description": "Boolean for enabling rate limiting on authentication endpoints.\n",
                        "version_added": "1.0.2",
                        "type": "boolean",
                        "example": None,
                        "default": "True",
                    },
                    "auth_rate_limit": {
                        "description": "Rate limit for authentication endpoints.\n",
                        "version_added": "1.0.2",
                        "type": "string",
                        "example": None,
                        "default": "5 per 40 second",
                    },
                    "update_fab_perms": {
                        "description": "Update FAB permissions and sync security manager roles\non webserver startup\n",
                        "version_added": "1.0.2",
                        "type": "string",
                        "example": None,
                        "default": "True",
                    },
                },
            }
        },
        "auth-managers": ["airflow.providers.fab.auth_manager.fab_auth_manager.FabAuthManager"],
        "dependencies": [
            "apache-airflow>=3.0.0.dev0",
            'apache-airflow-providers-common-compat>=1.2.1; python_version < "3.13"',
            'flask>=2.2,<2.3; python_version < "3.13"',
            'flask-login>=0.6.2; python_version < "3.13"',
            'jmespath>=0.7.0; python_version < "3.13"',
        ],
        "optional-dependencies": {"kerberos": ['kerberos>=1.3.0; python_version < "3.13"']},
        "devel-dependencies": ['kerberos>=1.3.0; python_version < "3.13"'],
    }
