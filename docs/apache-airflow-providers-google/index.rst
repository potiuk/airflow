 .. Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

 ..   http://www.apache.org/licenses/LICENSE-2.0

 .. Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.

``apache-airflow-providers-google``
===================================

Content
-------

.. toctree::
    :maxdepth: 1
    :caption: Guides

    Connection types <connections/index>
    Logging handlers <logging/index>
    Secrets backends <secrets-backends/google-cloud-secret-manager-backend>
    API Authentication backend <api-auth-backend/google-openid>
    Operators <operators/index>

.. toctree::
    :maxdepth: 1
    :caption: References

    Python API <_api/airflow/providers/google/index>
    Configuration <configurations-ref>

.. toctree::
    :maxdepth: 1
    :caption: Resources

    Example DAGs <example-dags>
    PyPI Repository <https://pypi.org/project/apache-airflow-providers-google/>

.. THE REMINDER OF THE FILE IS AUTOMATICALLY GENERATED. IT WILL BE OVERWRITTEN AT RELEASE TIME!


Package apache-airflow-providers-google
------------------------------------------------------

Release: 2.0.0

Provider package
----------------

This is a provider package for ``google`` provider. All classes for this provider package
are in ``airflow.providers.google`` python package.

Installation
------------

.. note::

    On November 2020, new version of PIP (20.3) has been released with a new, 2020 resolver. This resolver
    does not yet work with Apache Airflow and might lead to errors in installation - depends on your choice
    of extras. In order to install Airflow you need to either downgrade pip to version 20.2.4
    ``pip install --upgrade pip==20.2.4`` or, in case you use Pip 20.3, you need to add option
    ``--use-deprecated legacy-resolver`` to your pip install command.


You can install this package on top of an existing airflow 2.* installation via
``pip install apache-airflow-providers-google``

PIP requirements
----------------

======================================  ===================
PIP package                             Version required
======================================  ===================
``PyOpenSSL``
``google-ads``                          ``>=4.0.0,<8.0.0``
``google-api-python-client``            ``>=1.6.0,<2.0.0``
``google-auth-httplib2``                ``>=0.0.1``
``google-auth``                         ``>=1.0.0,<2.0.0``
``google-cloud-automl``                 ``>=2.1.0,<3.0.0``
``google-cloud-bigquery-datatransfer``  ``>=3.0.0,<4.0.0``
``google-cloud-bigtable``               ``>=1.0.0,<2.0.0``
``google-cloud-container``              ``>=0.1.1,<2.0.0``
``google-cloud-datacatalog``            ``>=3.0.0,<4.0.0``
``google-cloud-dataproc``               ``>=2.2.0,<3.0.0``
``google-cloud-dlp``                    ``>=0.11.0,<2.0.0``
``google-cloud-kms``                    ``>=2.0.0,<3.0.0``
``google-cloud-language``               ``>=1.1.1,<2.0.0``
``google-cloud-logging``                ``>=1.14.0,<2.0.0``
``google-cloud-memcache``               ``>=0.2.0``
``google-cloud-monitoring``             ``>=0.34.0,<2.0.0``
``google-cloud-os-login``               ``>=2.0.0,<3.0.0``
``google-cloud-pubsub``                 ``>=2.0.0,<3.0.0``
``google-cloud-redis``                  ``>=2.0.0,<3.0.0``
``google-cloud-secret-manager``         ``>=0.2.0,<2.0.0``
``google-cloud-spanner``                ``>=1.10.0,<2.0.0``
``google-cloud-speech``                 ``>=0.36.3,<2.0.0``
``google-cloud-storage``                ``>=1.30,<2.0.0``
``google-cloud-tasks``                  ``>=2.0.0,<3.0.0``
``google-cloud-texttospeech``           ``>=0.4.0,<2.0.0``
``google-cloud-translate``              ``>=1.5.0,<2.0.0``
``google-cloud-videointelligence``      ``>=1.7.0,<2.0.0``
``google-cloud-vision``                 ``>=0.35.2,<2.0.0``
``grpcio-gcp``                          ``>=0.2.2``
``json-merge-patch``                    ``~=0.2``
``pandas-gbq``
======================================  ===================

Cross provider package dependencies
-----------------------------------

Those are dependencies that might be needed in order to use all the features of the package.
You need to install the specified backport providers package in order to use them.

You can install such cross-provider dependencies when installing from PyPI. For example:

.. code-block:: bash

    pip install apache-airflow-providers-google[amazon]


========================================================================================================================  ====================
Dependent package                                                                                                         Extra
========================================================================================================================  ====================
`apache-airflow-providers-amazon <https://airflow.apache.org/docs/apache-airflow-providers-amazon>`_                      ``amazon``
`apache-airflow-providers-apache-cassandra <https://airflow.apache.org/docs/apache-airflow-providers-apache-cassandra>`_  ``apache.cassandra``
`apache-airflow-providers-cncf-kubernetes <https://airflow.apache.org/docs/apache-airflow-providers-cncf-kubernetes>`_    ``cncf.kubernetes``
`apache-airflow-providers-facebook <https://airflow.apache.org/docs/apache-airflow-providers-facebook>`_                  ``facebook``
`apache-airflow-providers-microsoft-azure <https://airflow.apache.org/docs/apache-airflow-providers-microsoft-azure>`_    ``microsoft.azure``
`apache-airflow-providers-microsoft-mssql <https://airflow.apache.org/docs/apache-airflow-providers-microsoft-mssql>`_    ``microsoft.mssql``
`apache-airflow-providers-mysql <https://airflow.apache.org/docs/apache-airflow-providers-mysql>`_                        ``mysql``
`apache-airflow-providers-oracle <https://airflow.apache.org/docs/apache-airflow-providers-oracle>`_                      ``oracle``
`apache-airflow-providers-postgres <https://airflow.apache.org/docs/apache-airflow-providers-postgres>`_                  ``postgres``
`apache-airflow-providers-presto <https://airflow.apache.org/docs/apache-airflow-providers-presto>`_                      ``presto``
`apache-airflow-providers-salesforce <https://airflow.apache.org/docs/apache-airflow-providers-salesforce>`_              ``salesforce``
`apache-airflow-providers-sftp <https://airflow.apache.org/docs/apache-airflow-providers-sftp>`_                          ``sftp``
`apache-airflow-providers-ssh <https://airflow.apache.org/docs/apache-airflow-providers-ssh>`_                            ``ssh``
========================================================================================================================  ====================


 .. Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

 ..   http://www.apache.org/licenses/LICENSE-2.0

 .. Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.


Changelog
---------

2.0.0
.....

Updated ``google-cloud-*`` libraries
````````````````````````````````````

This release of the provider package contains third-party library updates, which may require updating your
DAG files or custom hooks and operators, if you were using objects from those libraries.
Updating of these libraries is necessary to be able to use new features made available by new versions of
the libraries and to obtain bug fixes that are only available for new versions of the library.

Details are covered in the UPDATING.md files for each library, but there are some details
that you should pay attention to.


+-----------------------------------------------------------------------------------------------------+----------------------+---------------------+---------------------------------------------------------------------------------------------------------------------------------------+
| Library name                                                                                        | Previous constraints | Current constraints | Upgrade Documentation                                                                                                                 |
+=====================================================================================================+======================+=====================+=======================================================================================================================================+
| `google-cloud-bigquery-datatransfer <https://pypi.org/project/google-cloud-bigquery-datatransfer>`_ | ``>=0.4.0,<2.0.0``   | ``>=3.0.0,<4.0.0``  | `Upgrading google-cloud-bigquery-datatransfer <https://github.com/googleapis/python-bigquery-datatransfer/blob/master/UPGRADING.md>`_ |
+-----------------------------------------------------------------------------------------------------+----------------------+---------------------+---------------------------------------------------------------------------------------------------------------------------------------+
| `google-cloud-datacatalog <https://pypi.org/project/google-cloud-datacatalog>`_                     | ``>=0.5.0,<0.8``     | ``>=1.0.0,<2.0.0``  | `Upgrading google-cloud-datacatalog <https://github.com/googleapis/python-datacatalog/blob/master/UPGRADING.md>`_                     |
+-----------------------------------------------------------------------------------------------------+----------------------+---------------------+---------------------------------------------------------------------------------------------------------------------------------------+
| `google-cloud-os-login <https://pypi.org/project/google-cloud-os-login>`_                           | ``>=1.0.0,<2.0.0``   | ``>=2.0.0,<3.0.0``  | `Upgrading google-cloud-os-login <https://github.com/googleapis/python-oslogin/blob/master/UPGRADING.md>`_                            |
+-----------------------------------------------------------------------------------------------------+----------------------+---------------------+---------------------------------------------------------------------------------------------------------------------------------------+
| `google-cloud-pubsub <https://pypi.org/project/google-cloud-pubsub>`_                               | ``>=1.0.0,<2.0.0``   | ``>=2.0.0,<3.0.0``  | `Upgrading google-cloud-pubsub <https://github.com/googleapis/python-pubsub/blob/master/UPGRADING.md>`_                               |
+-----------------------------------------------------------------------------------------------------+----------------------+---------------------+---------------------------------------------------------------------------------------------------------------------------------------+
| `google-cloud-kms <https://pypi.org/project/google-cloud-kms>`_                                     | ``>=1.2.1,<2.0.0``   | ``>=2.0.0,<3.0.0``  | `Upgrading google-cloud-kms <https://github.com/googleapis/python-kms/blob/master/UPGRADING.md>`_                                     |
+-----------------------------------------------------------------------------------------------------+----------------------+---------------------+---------------------------------------------------------------------------------------------------------------------------------------+

The field names use the snake_case convention
`````````````````````````````````````````````

If your DAG uses an object from the above mentioned libraries passed by XCom, it is necessary to update the
naming convention of the fields that are read. Previously, the fields used the CamelSnake convention,
now the snake_case convention is used.

**Before:**

.. code-block:: python

    set_acl_permission = GCSBucketCreateAclEntryOperator(
        task_id="gcs-set-acl-permission",
        bucket=BUCKET_NAME,
        entity="user-{{ task_instance.xcom_pull('get-instance')['persistenceIamIdentity']"
        ".split(':', 2)[1] }}",
        role="OWNER",
    )


**After:**

.. code-block:: python

    set_acl_permission = GCSBucketCreateAclEntryOperator(
        task_id="gcs-set-acl-permission",
        bucket=BUCKET_NAME,
        entity="user-{{ task_instance.xcom_pull('get-instance')['persistence_iam_identity']"
        ".split(':', 2)[1] }}",
        role="OWNER",
    )



1.0.0
.....

Initial version of the provider.

Detailed changelog
------------------

2.0.0
.....

Latest change: 2021-01-19

==============================================================================================  ===========  ===============================================================================
Commit                                                                                          Committed    Subject
==============================================================================================  ===========  ===============================================================================
[1f6750420](https://github.com/apache/airflow/commit/1f67504208ec98d0c756a0445286538d72066d05)  2021-01-19   Implement target provider versioning tools
[309788e5e](https://github.com/apache/airflow/commit/309788e5e2023c598095a4ee00df417d94b6a5df)  2021-01-18   Refactor DataprocOperators to support google-cloud-dataproc 2.0 (#13256)
[7ec858c45](https://github.com/apache/airflow/commit/7ec858c4523b24e7a3d6dd1d49e3813e6eee7dff)  2021-01-17   updated Google DV360 Hook to fix SDF issue (#13703)
[ef8617ec9](https://github.com/apache/airflow/commit/ef8617ec9d6e4b7c433a29bd388f5102a7a17c11)  2021-01-14   Support google-cloud-tasks>=2.0.0 (#13347)
[189af5404](https://github.com/apache/airflow/commit/189af54043a6aa6e7557bda6cf7cfca229d0efd2)  2021-01-13   Add system tests for Stackdriver operators (#13644)
[a6f999b62](https://github.com/apache/airflow/commit/a6f999b62e3c9aeb10ab24342674d3670a8ad259)  2021-01-11   Support google-cloud-automl >=2.1.0 (#13505)
[947dbb73b](https://github.com/apache/airflow/commit/947dbb73bba736eb146f33117545a18fc2fd3c09)  2021-01-11   Support google-cloud-datacatalog>=3.0.0 (#13534)
[2fb68342b](https://github.com/apache/airflow/commit/2fb68342b01da4cb5d79ac9e5c0f7687d74351f3)  2021-01-07   Replace deprecated module and operator in example_tasks.py (#13527)
[003584bbf](https://github.com/apache/airflow/commit/003584bbf1d66a3545ad6e6fcdceb0410fc83696)  2021-01-05   Fix failing backport packages test (#13497)
[7d1ea4cb1](https://github.com/apache/airflow/commit/7d1ea4cb102e7d9878eeeaab5b098ae7767b844b)  2021-01-05   Replace deprecated module and operator in example_tasks.py (#13473)
[c7d75ad88](https://github.com/apache/airflow/commit/c7d75ad887cd12d5603563c5fa873c0e2f8975aa)  2021-01-05   Revert "Support google-cloud-datacatalog 3.0.0 (#13224)" (#13482)
[feb84057d](https://github.com/apache/airflow/commit/feb84057d34b2f64e3b5dcbaae2d3b18f5f564e4)  2021-01-04   Support google-cloud-datacatalog 3.0.0 (#13224)
[3a3e73998](https://github.com/apache/airflow/commit/3a3e7399810fd399d08f136e6936743c16508fc6)  2021-01-04   Fix insert_all method of BigQueryHook to support tables without schema (#13138)
[c33d2c06b](https://github.com/apache/airflow/commit/c33d2c06b68c8b9a5a36c965ab8be540a2dca967)  2021-01-02   Fix another pylint c-extension-no-member (#13438)
[f6518dd6a](https://github.com/apache/airflow/commit/f6518dd6a1217d906d863fe13dc37916efd78b3e)  2021-01-02   Generalize MLEngineStartTrainingJobOperator to custom images (#13318)
[9de712708](https://github.com/apache/airflow/commit/9de71270838ad3cc59043f1ab0bb6ca97af13622)  2020-12-31   Support google-cloud-bigquery-datatransfer>=3.0.0 (#13337)
[406181d64](https://github.com/apache/airflow/commit/406181d64ac32d133523ca52f954bc50a07defc4)  2020-12-31   Add Parquet data type to BaseSQLToGCSOperator (#13359)
[295d66f91](https://github.com/apache/airflow/commit/295d66f91446a69610576d040ba687b38f1c5d0a)  2020-12-30   Fix Grammar in PIP warning (#13380)
[13a9747bf](https://github.com/apache/airflow/commit/13a9747bf1d92020caa5d4dc825e096ce583f2df)  2020-12-28   Revert "Support google-cloud-tasks>=2.0.0 (#13334)" (#13341)
[04ec45f04](https://github.com/apache/airflow/commit/04ec45f045419ec87432ee285ac0828ab68008c3)  2020-12-28   Add DataprocCreateWorkflowTemplateOperator (#13338)
[1f712219f](https://github.com/apache/airflow/commit/1f712219fa8971d98bc486896603ce8109c42844)  2020-12-28   Support google-cloud-tasks>=2.0.0 (#13334)
[f4745c8ce](https://github.com/apache/airflow/commit/f4745c8ce1955c28676b5afe129a88a61aa743b9)  2020-12-26   Fix typo in example (#13321)
[e9d65bd45](https://github.com/apache/airflow/commit/e9d65bd4582b083914f2fc1213bea44cf41d1a08)  2020-12-24   Decode Remote Google Logs (#13115)
[e7aeacf33](https://github.com/apache/airflow/commit/e7aeacf335d373007a32ac65680ba6b5b19f5c9f)  2020-12-24   Add OracleToGCS Transfer (#13246)
[323084e97](https://github.com/apache/airflow/commit/323084e97ddacbc5512709bf0cad8f53082d16b0)  2020-12-24   Add timeout option to gcs hook methods. (#13156)
[0b626c804](https://github.com/apache/airflow/commit/0b626c8042b304a52d6c481fa6eb689d655f33d3)  2020-12-22   Support google-cloud-redis>=2.0.0 (#13117)
[9042a5855](https://github.com/apache/airflow/commit/9042a585539a18953d688fff455438f4061732d1)  2020-12-22   Add more operators to example DAGs for Cloud Tasks (#13235)
[8c00ec89b](https://github.com/apache/airflow/commit/8c00ec89b97aa6e725379d08c8ff29a01be47e73)  2020-12-22   Support google-cloud-pubsub>=2.0.0 (#13127)
[b26b0df5b](https://github.com/apache/airflow/commit/b26b0df5b03c4cd826fd7b2dff5771d64e18e6b7)  2020-12-22   Update compatibility with google-cloud-kms>=2.0 (#13124)
[9a1d3820d](https://github.com/apache/airflow/commit/9a1d3820d6f1373df790da8751f25e723f9ce037)  2020-12-22   Support google-cloud-datacatalog>=1.0.0 (#13097)
[f95b1c9c9](https://github.com/apache/airflow/commit/f95b1c9c95c059e85ad5676daaa191929785fee2)  2020-12-21   Add regional support to dataproc workflow template operators (#12907)
[6cf76d7ac](https://github.com/apache/airflow/commit/6cf76d7ac01270930de7f105fb26428763ee1d4e)  2020-12-18   Fix typo in pip upgrade command :( (#13148)
[23f27c1b1](https://github.com/apache/airflow/commit/23f27c1b1cdbcb6bb50fd2aa772aeda7151d5634)  2020-12-18   Add system tests for CloudKMSHook (#13122)
[cddbf81b1](https://github.com/apache/airflow/commit/cddbf81b12650ee5905b0f762c1213caa1d3a7ed)  2020-12-17   Fix Google BigQueryHook method get_schema() (#13136)
[1259c712a](https://github.com/apache/airflow/commit/1259c712a42d69135dc389de88f79942c70079a3)  2020-12-17   Update compatibility with google-cloud-os-login>=2.0.0 (#13126)
[bcf77586e](https://github.com/apache/airflow/commit/bcf77586eff9907fa057cf2633115d5ab3e4142b)  2020-12-16   Fix Data Catalog operators (#13096)
[5090fb0c8](https://github.com/apache/airflow/commit/5090fb0c8967d2d8719c6f4a468f2151395b5444)  2020-12-15   Add script to generate integrations.json (#13073)
[b4b9cf559](https://github.com/apache/airflow/commit/b4b9cf55970ca41fa7852ab8d25e59f4c379f8c2)  2020-12-14   Check for missing references to operator guides (#13059)
[1c1ef7ee6](https://github.com/apache/airflow/commit/1c1ef7ee693fead93e269dfd9774a72b6eed2e85)  2020-12-14   Add project_id to client inside BigQuery hook update_table method (#13018)
==============================================================================================  ===========  ===============================================================================
