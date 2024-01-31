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