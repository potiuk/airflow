
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


Package apache-airflow-providers-google
------------------------------------------------------

Google services including:

  - `Google Ads <https://ads.google.com/>`__
  - `Google Cloud (GCP) <https://cloud.google.com/>`__
  - `Google Firebase <https://firebase.google.com/>`__
  - `Google Marketing Platform <https://marketingplatform.google.com/>`__
  - `Google Workspace <https://workspace.google.pl/>`__ (formerly Google Suite)


This is detailed commit list of changes for versions provider package: ``google``.
For high-level changelog, see :doc:`package information including changelog <index>`.

2.0.0
.....

Latest change: 2021-01-24

================================================================================================  ===========  =========================================================================================
Commit                                                                                            Committed    Subject
================================================================================================  ===========  =========================================================================================
`a35b24ef2 <https://github.com/apache/airflow/commit/a35b24ef2ead429d306ca975567a90a4ddd23291>`_  2021-01-24   ``fixup! Remove provider generated docs``
`c7750a61e <https://github.com/apache/airflow/commit/c7750a61e27ff63cefa1398f1906bc73e29c26b0>`_  2021-01-24   ``Remove provider generated docs``
`f473ca713 <https://github.com/apache/airflow/commit/f473ca7130f844bc59477674e641b42b80698bb7>`_  2021-01-24   ``Replace 'google_cloud_storage_conn_id' by 'gcp_conn_id' when using 'GCSHook' (#13851)``
`a9ac2b040 <https://github.com/apache/airflow/commit/a9ac2b040b64de1aa5d9c2b9def33334e36a8d22>`_  2021-01-23   ``Switch to f-strings using flynt. (#13732)``
`9592be88e <https://github.com/apache/airflow/commit/9592be88e57cc7f59b9eac978292abd4d7692c0b>`_  2021-01-22   ``Fix Google Spanner example dag (#13842)``
`af52fdb51 <https://github.com/apache/airflow/commit/af52fdb51152a72441a44a271e498b1ec20dfd57>`_  2021-01-22   ``Improve environment variables in GCP Dataflow system test (#13841)``
`e7946f1cb <https://github.com/apache/airflow/commit/e7946f1cb7c144181443cbcc843d90bd597b09b5>`_  2021-01-22   ``Improve environment variables in GCP Datafusion system test (#13837)``
`61c1d6ec6 <https://github.com/apache/airflow/commit/61c1d6ec6ce638f8ccd76705f69e9474c308389a>`_  2021-01-22   ``Improve environment variables in GCP Memorystore system test (#13833)``
`202f66093 <https://github.com/apache/airflow/commit/202f66093ad12c293f97204b0775bef2b077cd9a>`_  2021-01-22   ``Improve environment variables in GCP Lifeciences system test (#13834)``
`70bf307f3 <https://github.com/apache/airflow/commit/70bf307f3894214c523701940b89ac0b991a3a63>`_  2021-01-21   ``Add How To Guide for Dataflow (#13461)``
`3fd5ef355 <https://github.com/apache/airflow/commit/3fd5ef355556cf0ad7896bb570bbe4b2eabbf46e>`_  2021-01-21   ``Add missing logos for integrations (#13717)``
`309788e5e <https://github.com/apache/airflow/commit/309788e5e2023c598095a4ee00df417d94b6a5df>`_  2021-01-18   ``Refactor DataprocOperators to support google-cloud-dataproc 2.0 (#13256)``
`7ec858c45 <https://github.com/apache/airflow/commit/7ec858c4523b24e7a3d6dd1d49e3813e6eee7dff>`_  2021-01-17   ``updated Google DV360 Hook to fix SDF issue (#13703)``
`ef8617ec9 <https://github.com/apache/airflow/commit/ef8617ec9d6e4b7c433a29bd388f5102a7a17c11>`_  2021-01-14   ``Support google-cloud-tasks>=2.0.0 (#13347)``
`189af5404 <https://github.com/apache/airflow/commit/189af54043a6aa6e7557bda6cf7cfca229d0efd2>`_  2021-01-13   ``Add system tests for Stackdriver operators (#13644)``
`a6f999b62 <https://github.com/apache/airflow/commit/a6f999b62e3c9aeb10ab24342674d3670a8ad259>`_  2021-01-11   ``Support google-cloud-automl >=2.1.0 (#13505)``
`947dbb73b <https://github.com/apache/airflow/commit/947dbb73bba736eb146f33117545a18fc2fd3c09>`_  2021-01-11   ``Support google-cloud-datacatalog>=3.0.0 (#13534)``
`2fb68342b <https://github.com/apache/airflow/commit/2fb68342b01da4cb5d79ac9e5c0f7687d74351f3>`_  2021-01-07   ``Replace deprecated module and operator in example_tasks.py (#13527)``
`003584bbf <https://github.com/apache/airflow/commit/003584bbf1d66a3545ad6e6fcdceb0410fc83696>`_  2021-01-05   ``Fix failing backport packages test (#13497)``
`7d1ea4cb1 <https://github.com/apache/airflow/commit/7d1ea4cb102e7d9878eeeaab5b098ae7767b844b>`_  2021-01-05   ``Replace deprecated module and operator in example_tasks.py (#13473)``
`c7d75ad88 <https://github.com/apache/airflow/commit/c7d75ad887cd12d5603563c5fa873c0e2f8975aa>`_  2021-01-05   ``Revert "Support google-cloud-datacatalog 3.0.0 (#13224)" (#13482)``
`feb84057d <https://github.com/apache/airflow/commit/feb84057d34b2f64e3b5dcbaae2d3b18f5f564e4>`_  2021-01-04   ``Support google-cloud-datacatalog 3.0.0 (#13224)``
`3a3e73998 <https://github.com/apache/airflow/commit/3a3e7399810fd399d08f136e6936743c16508fc6>`_  2021-01-04   ``Fix insert_all method of BigQueryHook to support tables without schema (#13138)``
`c33d2c06b <https://github.com/apache/airflow/commit/c33d2c06b68c8b9a5a36c965ab8be540a2dca967>`_  2021-01-02   ``Fix another pylint c-extension-no-member (#13438)``
`f6518dd6a <https://github.com/apache/airflow/commit/f6518dd6a1217d906d863fe13dc37916efd78b3e>`_  2021-01-02   ``Generalize MLEngineStartTrainingJobOperator to custom images (#13318)``
`9de712708 <https://github.com/apache/airflow/commit/9de71270838ad3cc59043f1ab0bb6ca97af13622>`_  2020-12-31   ``Support google-cloud-bigquery-datatransfer>=3.0.0 (#13337)``
`406181d64 <https://github.com/apache/airflow/commit/406181d64ac32d133523ca52f954bc50a07defc4>`_  2020-12-31   ``Add Parquet data type to BaseSQLToGCSOperator (#13359)``
`295d66f91 <https://github.com/apache/airflow/commit/295d66f91446a69610576d040ba687b38f1c5d0a>`_  2020-12-30   ``Fix Grammar in PIP warning (#13380)``
`13a9747bf <https://github.com/apache/airflow/commit/13a9747bf1d92020caa5d4dc825e096ce583f2df>`_  2020-12-28   ``Revert "Support google-cloud-tasks>=2.0.0 (#13334)" (#13341)``
`04ec45f04 <https://github.com/apache/airflow/commit/04ec45f045419ec87432ee285ac0828ab68008c3>`_  2020-12-28   ``Add DataprocCreateWorkflowTemplateOperator (#13338)``
`1f712219f <https://github.com/apache/airflow/commit/1f712219fa8971d98bc486896603ce8109c42844>`_  2020-12-28   ``Support google-cloud-tasks>=2.0.0 (#13334)``
`f4745c8ce <https://github.com/apache/airflow/commit/f4745c8ce1955c28676b5afe129a88a61aa743b9>`_  2020-12-26   ``Fix typo in example (#13321)``
`e9d65bd45 <https://github.com/apache/airflow/commit/e9d65bd4582b083914f2fc1213bea44cf41d1a08>`_  2020-12-24   ``Decode Remote Google Logs (#13115)``
`e7aeacf33 <https://github.com/apache/airflow/commit/e7aeacf335d373007a32ac65680ba6b5b19f5c9f>`_  2020-12-24   ``Add OracleToGCS Transfer (#13246)``
`323084e97 <https://github.com/apache/airflow/commit/323084e97ddacbc5512709bf0cad8f53082d16b0>`_  2020-12-24   ``Add timeout option to gcs hook methods. (#13156)``
`0b626c804 <https://github.com/apache/airflow/commit/0b626c8042b304a52d6c481fa6eb689d655f33d3>`_  2020-12-22   ``Support google-cloud-redis>=2.0.0 (#13117)``
`9042a5855 <https://github.com/apache/airflow/commit/9042a585539a18953d688fff455438f4061732d1>`_  2020-12-22   ``Add more operators to example DAGs for Cloud Tasks (#13235)``
`8c00ec89b <https://github.com/apache/airflow/commit/8c00ec89b97aa6e725379d08c8ff29a01be47e73>`_  2020-12-22   ``Support google-cloud-pubsub>=2.0.0 (#13127)``
`b26b0df5b <https://github.com/apache/airflow/commit/b26b0df5b03c4cd826fd7b2dff5771d64e18e6b7>`_  2020-12-22   ``Update compatibility with google-cloud-kms>=2.0 (#13124)``
`9a1d3820d <https://github.com/apache/airflow/commit/9a1d3820d6f1373df790da8751f25e723f9ce037>`_  2020-12-22   ``Support google-cloud-datacatalog>=1.0.0 (#13097)``
`f95b1c9c9 <https://github.com/apache/airflow/commit/f95b1c9c95c059e85ad5676daaa191929785fee2>`_  2020-12-21   ``Add regional support to dataproc workflow template operators (#12907)``
`6cf76d7ac <https://github.com/apache/airflow/commit/6cf76d7ac01270930de7f105fb26428763ee1d4e>`_  2020-12-18   ``Fix typo in pip upgrade command :( (#13148)``
`23f27c1b1 <https://github.com/apache/airflow/commit/23f27c1b1cdbcb6bb50fd2aa772aeda7151d5634>`_  2020-12-18   ``Add system tests for CloudKMSHook (#13122)``
`cddbf81b1 <https://github.com/apache/airflow/commit/cddbf81b12650ee5905b0f762c1213caa1d3a7ed>`_  2020-12-17   ``Fix Google BigQueryHook method get_schema() (#13136)``
`1259c712a <https://github.com/apache/airflow/commit/1259c712a42d69135dc389de88f79942c70079a3>`_  2020-12-17   ``Update compatibility with google-cloud-os-login>=2.0.0 (#13126)``
`bcf77586e <https://github.com/apache/airflow/commit/bcf77586eff9907fa057cf2633115d5ab3e4142b>`_  2020-12-16   ``Fix Data Catalog operators (#13096)``
`5090fb0c8 <https://github.com/apache/airflow/commit/5090fb0c8967d2d8719c6f4a468f2151395b5444>`_  2020-12-15   ``Add script to generate integrations.json (#13073)``
`b4b9cf559 <https://github.com/apache/airflow/commit/b4b9cf55970ca41fa7852ab8d25e59f4c379f8c2>`_  2020-12-14   ``Check for missing references to operator guides (#13059)``
`1c1ef7ee6 <https://github.com/apache/airflow/commit/1c1ef7ee693fead93e269dfd9774a72b6eed2e85>`_  2020-12-14   ``Add project_id to client inside BigQuery hook update_table method (#13018)``
================================================================================================  ===========  =========================================================================================
