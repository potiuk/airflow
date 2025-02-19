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
        "package-name": "apache-airflow-providers-apache-beam",
        "name": "Apache Beam",
        "description": "`Apache Beam <https://beam.apache.org/>`__.\n",
        "state": "ready",
        "source-date-epoch": 1734527138,
        "versions": [
            "6.0.0",
            "5.9.1",
            "5.9.0",
            "5.8.1",
            "5.8.0",
            "5.7.2",
            "5.7.1",
            "5.7.0",
            "5.6.3",
            "5.6.2",
            "5.6.1",
            "5.6.0",
            "5.5.0",
            "5.4.0",
            "5.3.0",
            "5.2.3",
            "5.2.2",
            "5.2.1",
            "5.2.0",
            "5.1.1",
            "5.1.0",
            "5.0.0",
            "4.3.0",
            "4.2.0",
            "4.1.1",
            "4.1.0",
            "4.0.0",
            "3.4.0",
            "3.3.0",
            "3.2.1",
            "3.2.0",
            "3.1.0",
            "3.0.1",
            "3.0.0",
            "2.0.0",
            "1.0.1",
            "1.0.0",
        ],
        "excluded-python-versions": ["3.13"],
        "integrations": [
            {
                "integration-name": "Apache Beam",
                "external-doc-url": "https://beam.apache.org/",
                "how-to-guide": ["/docs/apache-airflow-providers-apache-beam/operators.rst"],
                "tags": ["apache"],
            }
        ],
        "operators": [
            {
                "integration-name": "Apache Beam",
                "python-modules": ["airflow.providers.apache.beam.operators.beam"],
            }
        ],
        "hooks": [
            {
                "integration-name": "Apache Beam",
                "python-modules": ["airflow.providers.apache.beam.hooks.beam"],
            }
        ],
        "triggers": [
            {
                "integration-name": "Apache Beam",
                "python-modules": ["airflow.providers.apache.beam.triggers.beam"],
            }
        ],
        "dependencies": [
            "apache-airflow>=2.9.0",
            'pyarrow>=14.0.1; python_version < "3.13"',
            'numpy>=1.26.0; python_version < "3.13\'"',
        ],
        "optional-dependencies": {
            "google": [],
            "common.compat": ['apache-airflow-providers-common-compat; python_version < "3.13"'],
        },
    }
