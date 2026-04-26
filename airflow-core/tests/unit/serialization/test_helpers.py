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


def test_serialize_template_field_with_very_small_max_length(monkeypatch):
    """Test that truncation message is prioritized even for very small max_length."""
    monkeypatch.setenv("AIRFLOW__CORE__MAX_TEMPLATED_FIELD_LENGTH", "1")

    from airflow.serialization.helpers import serialize_template_field

    result = serialize_template_field("This is a long string", "test")

    # The truncation message should be shown even if it exceeds max_length
    # This ensures users always see why content is truncated
    assert result
    assert "Truncated. You can change this behaviour" in result


@pytest.mark.enable_redact
def test_serialize_template_field_masks_nested_sensitive_keys_on_truncation(monkeypatch):
    """Nested sensitive-key masking applies consistently across the truncation path.

    A value under a documented sensitive key (``password``, ``token``, ``secret``,
    ``api_key``) is masked recursively by ``redact()`` when the structured value
    is walked. The oversized branch must redact while still structured so that
    nested-key context is preserved before stringification — otherwise the post-
    stringify ``redact()`` call only sees the outer field name and the recursive
    walker cannot reach the inner key.
    """
    monkeypatch.setenv("AIRFLOW__CORE__MAX_TEMPLATED_FIELD_LENGTH", "200")

    from airflow.serialization.helpers import serialize_template_field

    nested_value = "REGRESSION-FIXTURE-NESTED-PASSWORD-VALUE"
    payload = {"nested": {"password": nested_value, "zz_pad": "A" * 500}}

    result = serialize_template_field(payload, "templates_dict")

    assert isinstance(result, str)
    assert "Truncated. You can change this behaviour" in result
    assert nested_value not in result
    assert "***" in result
