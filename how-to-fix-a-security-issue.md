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
   The Apache Airflow community actively monitors security channels and mailing lists for reports of vulnerabilities. The issues are reported by reporters to security@apache.airflow.org email id.

2. **Security Advisories**:
   When vulnerabilities are fixed, the release managers will issue security advisories to inform users about the
   vulnerabilities and provide some guidance on mitigation.

3. **Security Features**:
   The Apache Airflow project continuously works on introducing new security features and enhancing the already existing
   ones to improve the overall security posture of the platform.

4. **Community Engagement**:
   The Apache Airflow project encourages responsible vulnerability disclosure from users and security researchers
   to ensure prompt and responsible handling of security issues. Airflow security team follows an on-call and handles reports received this way.


## Best Practices

*  When we implement low severity issues for security, sometimes the ones that are even    not worthy of having a CVE, we avoid describing it as a security feature to avoid web scrappers / tools running against our repository commits
   to raise reports that were not subscribed to. These tools might as well violate our security practices.
