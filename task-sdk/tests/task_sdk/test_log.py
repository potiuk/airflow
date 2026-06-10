#
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

from unittest import mock

from uuid6 import uuid7

from airflow.sdk import log as sdk_log


def _make_ti():
    ti = mock.MagicMock()
    ti.id = uuid7()
    return ti


def _make_logger():
    """Build a ``FilteringBoundLogger``-like object exposing ``_logger`` and ``warning``.

    The real logger passed to ``upload_to_remote`` is the task's own log writer,
    so warnings emitted through it land in the task logs the user sees. The tests
    assert against ``logger.warning`` for exactly that reason.
    """
    logger = mock.MagicMock()
    logger._logger = mock.MagicMock()
    return logger


def _remote_logging(enabled: bool):
    """Patch the SDK conf so ``logging/remote_logging`` reads as ``enabled``."""
    conf = mock.MagicMock()
    conf.getboolean.return_value = enabled
    return mock.patch("airflow.sdk.configuration.conf", conf)


class TestUploadToRemote:
    def test_warns_in_task_logs_when_remote_logging_enabled_but_handler_unavailable(self):
        ti = _make_ti()
        logger = _make_logger()
        with (
            _remote_logging(enabled=True),
            mock.patch.object(sdk_log, "load_remote_log_handler", return_value=None),
        ):
            sdk_log.upload_to_remote(logger, ti)

        logger.warning.assert_called_once()
        _, kwargs = logger.warning.call_args
        assert kwargs["ti_id"] == str(ti.id)

    def test_silent_when_remote_logging_disabled_and_handler_unavailable(self):
        """The default install (no remote logging) must not warn on every task."""
        ti = _make_ti()
        logger = _make_logger()
        with (
            _remote_logging(enabled=False),
            mock.patch.object(sdk_log, "load_remote_log_handler", return_value=None),
        ):
            sdk_log.upload_to_remote(logger, ti)

        logger.warning.assert_not_called()

    def test_warns_when_path_resolution_fails(self):
        ti = _make_ti()
        logger = _make_logger()
        handler = mock.MagicMock()
        boom = RuntimeError("cannot resolve path")
        with (
            mock.patch.object(sdk_log, "load_remote_log_handler", return_value=handler),
            mock.patch.object(sdk_log, "relative_path_from_logger", side_effect=boom),
        ):
            sdk_log.upload_to_remote(logger, ti)

        logger.warning.assert_called_once()
        _, kwargs = logger.warning.call_args
        assert kwargs["ti_id"] == str(ti.id)
        assert kwargs["error"] == str(boom)
        handler.upload.assert_not_called()

    def test_warns_in_task_logs_when_upload_fails(self, tmp_path):
        ti = _make_ti()
        logger = _make_logger()
        handler = mock.MagicMock()
        boom = RuntimeError("s3 unreachable")
        handler.upload.side_effect = boom
        relative = tmp_path / "dag_id" / "run_id" / "task.log"
        with (
            mock.patch.object(sdk_log, "load_remote_log_handler", return_value=handler),
            mock.patch.object(sdk_log, "relative_path_from_logger", return_value=relative),
        ):
            sdk_log.upload_to_remote(logger, ti)

        logger.warning.assert_called_once()
        _, kwargs = logger.warning.call_args
        assert kwargs["ti_id"] == str(ti.id)
        assert kwargs["log_relative_path"] == relative.as_posix()
        assert kwargs["error"] == str(boom)
        handler.upload.assert_called_once_with(relative.as_posix(), ti)

    def test_silent_when_relative_path_is_none(self):
        ti = _make_ti()
        logger = _make_logger()
        handler = mock.MagicMock()
        with (
            mock.patch.object(sdk_log, "load_remote_log_handler", return_value=handler),
            mock.patch.object(sdk_log, "relative_path_from_logger", return_value=None),
        ):
            sdk_log.upload_to_remote(logger, ti)

        logger.warning.assert_not_called()
        handler.upload.assert_not_called()

    def test_silent_on_success(self, tmp_path):
        ti = _make_ti()
        logger = _make_logger()
        handler = mock.MagicMock()
        relative = tmp_path / "dag_id" / "run_id" / "task.log"
        with (
            mock.patch.object(sdk_log, "load_remote_log_handler", return_value=handler),
            mock.patch.object(sdk_log, "relative_path_from_logger", return_value=relative),
        ):
            sdk_log.upload_to_remote(logger, ti)

        logger.warning.assert_not_called()
        handler.upload.assert_called_once_with(relative.as_posix(), ti)
