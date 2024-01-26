<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Confirmation of receiving the report](#confirmation-of-receiving-the-report)
- [Immediate response for DOS issues triggered by Authenticated users](#immediate-response-for-dos-issues-triggered-by-authenticated-users)
- [Immediate response for self-XSS issues triggered by Authenticated users](#immediate-response-for-self-xss-issues-triggered-by-authenticated-users)
- [Positive Assessment response](#positive-assessment-response)
- [Negative Assessment response](#negative-assessment-response)
- [Automated scanning results](#automated-scanning-results)
- [DOS/RCE/Arbitrary read via Test Connection](#dosrcearbitrary-read-via-test-connection)
- [When someone submits a media report](#when-someone-submits-a-media-report)
- [Or an alternative response](#or-an-alternative-response)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Confirmation of receiving the report

Thanks for the report and for trying to make Airflow secure.

We registered the issue. You can expect that we will come back to you with the result of our assessment
according to our security policy https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

# Immediate response for DOS issues triggered by Authenticated users

Thanks for keeping Airflow secure.

We have discussed similar concerns in the past and consider such generic reports concerning those
kinds of issues invalid. Unless you can provide a specific scenario where it can be exploited and
Confidentiality, Availability, and Integrity of Airflow deployment are breached in a meaningful way,
we consider that as a regular issue, and we encourage people like you to submit fixes via PR using our
regular GitHub contribution process. That's an easy way to become one of more than 2700
contributors, and we encourage directly fixing such issues in PRs without even creating GitHub Issues for them.

The reason for that is that Airflow is not publicly available software. When you run Airflow in an
internal network, the users of Airflow are known once authenticated, and the most harm that can be
done is to crash a particular process or make an internal Denial Of Service, but we do not consider that
as CVE-worthy and generally advisory-worthy.

More details about it in our policy: https://github.com/apache/airflow/security/policy#is-this-really-a-security-vulnerability-

# Immediate response for self-XSS issues triggered by Authenticated users

Thanks for keeping Airflow secure.

We have discussed similar concerns in the past and consider such reports concerning those
kinds of issues as invalid. Unless you can provide a specific scenario where it can be exploited
and Confidentiality, Availability, and Integrity of Airflow deployment are breached in a meaningful way,
we consider that as a regular issue, and we encourage people like you to submit fixes via PR using
our regular GitHub contribution process. That's an easy way to become one of more than 2700
contributors, and we encourage directly fixing such issues in PRs without even creating
GitHub Issues for them.

The reason for that is that Airflow is not publicly available software. When you run Airflow in an internal
network, the users of Airflow are known once authenticated, and the most harm that can be done is to make
internal XSS to themselves, but we do not consider it CVE-worthy and generally advisory-worthy.

More details about it in our policy: https://github.com/apache/airflow/security/policy#is-this-really-a-security-vulnerability-

# Positive Assessment response

Thanks again for keeping Airflow secure. We assessed your request
and we decided that this is a SEVERITY severity issue.

We followed https://github.com/apache/airflow/security/policy#how-do-we-assess-severity-of-the-issue- to
assess the severity). The CVE for this issue is CVE_ID, and we expect it to be solved in the next Airflow release.
Please monitor our announcements as explained in https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

# Negative Assessment response

Thanks again for keeping Airflow secure. We assessed your request, and we decided that this is not a
CVE-worthy issue.

HERE DETAILED EXPLANATION FOLLOWS

# Automated scanning results

Thanks for that (undoubtedly coming from automated scanning) question. While we appreciate your attempts to
make the world a more secure place, you should not use such emails to send us automated scanning results
like this. This is against our policy and clearly explained there: https://github.com/apache/airflow/security/policy

We are using our own automated tooling to detect and prevent issues, and we have a security team that
manages such issues.

Automated emails like that without human reviewing the report and assessing if it is a danger or not
and without providing a reproducible scenario where Availability, Confidentiality or Integrity are affected
and where our Security Model (https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html)
is compromised are causing us significant overhead. We would appreciate if you stop sending those emails. Unless
someone from your security team will assess them, provide a reproducible scenario and assess that yes,
such an issue actually compromises our model.

If you commit to doing this, and add those reproducible scenarios, then yes we will gladly receive such
reports as they will follow our policy https://github.com/apache/airflow/security/policy.

Can you please confirm that you understand that and you will follow the policy in the future?

Also, the Apache Software Foundation runs their own disclosure and publishing of CVEs, so you should get
it from there if we decide it is CVE worthy (and we do follow and review all such changes).


# DOS/RCE/Arbitrary read via Test Connection

Thanks for keeping things secure for airflow, but this request is invalid.

It is described in our model, and the issue has already been addressed https://nvd.nist.gov/vuln/detail/CVE-2023-37379

We identified that the test connection feature opens up various ways for how users who have access to it could abuse
various kinds of capabilities given by various kinds of connections: RCE, arbitrary file read,
Denial of service and likely all kinds of capabilities that are often (in systems that are open up to public
use, given to users with no high privileges, can be considered a vulnerability).

We addressed it in Airflow 2.7.0 by:

* disabling test connection by default
* informing our users that enabling test connection is dangerous and you should only do it when you know about
  all those capabilities you implicitly give those users who have connection editing capabilities
* clarifying in our security model

We explained in release notes and communication when we released
Airflow 2.7 that users who have connection editing capabilities are highly privileged and that they
should be trusted not to abuse the capabilities that connection editing gives them (that includes
the scenario that you described).

This is not at all strange - this user has access to all the authentication and password information
for all the systems that Airflow interacts with, so giving access to that functionality and enabling
"test connection" should be very carefully controlled. Our security model is very clear about it.
Please make sure to read it again and digest it before responding to that email and
sending yet-another-similar-report.

You can read more about it in Airflow's security model https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html

Connection editing users have such capabilities. Our users are aware of that, and this is intended. We are not planning to do anything about it.

Actually, the approach we took where we make sure it's clear such capabilities are
available for "Connection Editing" users - is far more secure and safe than trying to address all
kinds of connections - because our users might have their own providers and connections, and fixing
"one" of the connections is not approaching the problem in a "systematic" way and gives a false sense
of security - which is often worse than being aware that certain features are generally dangerous
when enabled, or that certain roles - when granted - give the users some insecure capabilities.
We chose the - far better, in our opinion - approach where we not only disabled the test connection
by default but also clearly informed our users - specifically deployment managers, that the
"Connection Editing" role has potentially dangerous capabilities, and users who have this role
should be highly trusted that they won't abuse it. This is both - fairer to our users and more
secure in general because otherwise, our users would not be aware of that and could give access to
the role to people who are not highly trusted (and they could abuse similar capabilities coming
from 100s of other connections - that are not even controlled by us, nor could we provide
any kinds of advisories for those.

Please consider a "Connection Editing" user similar to a "root" user having access to all the systems and
highly privileged, capable of performing RCE and similar with any of the systems, especially
when test connection is enabled.

Kindly ask you to consider that in your future research.

# When someone submits a media report

When submitting your report, please consider sending it in plain text format rather
than as an image or video file. Plain text allows for immediate access and straightforward
handling of the report's content, making it easier to process and analyze. Images or videos,
on the other hand, involve extra steps for extraction or transcription, which can slow down the review process.

By providing your report in plain text, you're not only simplifying its accessibility but also
contributing to quicker data processing. This streamlined approach enhances efficiency and
productivity in working with your shared information. Your cooperation in re-submitting
the report in plain text format would be greatly appreciated and will significantly expedite
our review process. Thank you for your understanding!

# Or an alternative response

While including a video or image might offer supplementary information, it's important to ensure that
all the content within these visuals is also provided in plain text. This allows for comprehensive
accessibility and easy referencing to the information presented in the multimedia content.

When a video or image is attached, it's incredibly helpful if the details, data, or any
pertinent information shared within these files are also provided in plain text format. This enables
a seamless review and extraction of key points, guaranteeing that all information is readily
accessible and available for analysis.

Therefore, in addition to any multimedia files submitted, kindly ensure that all contained information
is also presented in plain text. This practice ensures that nothing crucial is missed and enables
a quicker and more efficient review process. Your cooperation in providing comprehensive
plain-text details will be greatly appreciated.

Thank you!
