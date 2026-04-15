<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Fixing Security Issues in Airflow](#fixing-security-issues-in-airflow)
  - [Process](#process)
  - [Best Practices](#best-practices)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Fixing Security Issues in Airflow

Generally speaking, Apache Airflow addresses security issues through the following steps:

## Process

1. **Vulnerability Identification**:
   The Apache Airflow community actively monitors security channels and mailing lists for reports of vulnerabilities. Issues are reported to the `security@airflow.apache.org` email address.

2. **Security Advisories**:
   When vulnerabilities are fixed, the release managers issue security advisories to inform users about the
   vulnerabilities and provide guidance on mitigation.

3. **Security Features**:
   The Apache Airflow project continuously works on introducing new security features and enhancing existing
   ones to improve the overall security posture of the platform.

4. **Community Engagement**:
   The Apache Airflow project encourages responsible vulnerability disclosure from users and security researchers
   to ensure prompt and responsible handling of security issues. The Airflow security team follows an on-call rotation and handles reports received this way.


## Best Practices

*  When we implement low-severity security fixes — sometimes ones that are not even worthy of a CVE — we avoid describing them as security features. This prevents web scrapers and tools running against our repository commits
   from raising reports about issues they were not originally aware of. Such tools may themselves violate our security practices.
