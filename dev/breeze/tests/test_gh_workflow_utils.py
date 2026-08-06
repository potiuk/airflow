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
from __future__ import annotations

import pytest

from airflow_breeze.utils import gh_workflow_utils
from airflow_breeze.utils.gh_workflow_utils import trigger_workflow_and_monitor
from airflow_breeze.utils.shared_options import set_dry_run


@pytest.fixture
def dry_run():
    set_dry_run(True)
    yield
    set_dry_run(False)


@pytest.fixture(autouse=True)
def no_gh_version_check(monkeypatch):
    monkeypatch.setattr(gh_workflow_utils, "make_sure_gh_is_installed", lambda: None)


def test_dry_run_does_not_look_up_or_monitor_a_run(dry_run, monkeypatch):
    def fail(*args, **kwargs):
        raise AssertionError("should not be reached in dry run mode")

    monkeypatch.setattr(gh_workflow_utils, "get_workflow_run_id", fail)
    monkeypatch.setattr(gh_workflow_utils, "monitor_workflow_run", fail)
    monkeypatch.setattr(gh_workflow_utils.time, "sleep", fail)

    trigger_workflow_and_monitor(
        workflow_name="release-constraints.yml",
        repo="apache/airflow",
        version="3.2.0rc1",
        ref="v3-2-stable",
    )


def test_run_is_monitored_when_not_in_dry_run(monkeypatch):
    monitored = []
    monkeypatch.setattr(gh_workflow_utils, "tigger_workflow", lambda **kwargs: None)
    monkeypatch.setattr(gh_workflow_utils, "get_workflow_run_id", lambda **kwargs: 42)
    monkeypatch.setattr(gh_workflow_utils, "monitor_workflow_run", lambda **kwargs: monitored.append(kwargs))

    trigger_workflow_and_monitor(workflow_name="release-constraints.yml", repo="apache/airflow")

    assert monitored == [{"run_id": "42", "repo": "apache/airflow"}]
