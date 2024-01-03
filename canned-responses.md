# Confirmation of receiving the report

Thanks for the report and trying to make Airflow secure.

We registered the issue. You can expect that we will come back to you with result of our assessment
according to our security policy https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

# Immediate response for DOS issues triggered by Authenticated users

Thanks for keeping Airflow secure.

We have discussed similar concerns in the past - and we consider such generic reports concerning those
kinds of issues as invalid. Unless you can provide a specific scenario where it can be exploited and
Confidentiality, Availability and Integrity of Airflow deployment are breached in a meaningful way,
we consider that as a regular issue and we encourage people like you to submit fixes via PR using our
regular GitHub contribution process. That's an easy way to become one of more than 2700
contributors and we encourage directly fixing such issues in PRs without even creating GitHub Issues for them.

The reason for that is that Airflow is not publicly available software. When you run Airflow in an
internal network, the users of Airflow are known once authenticated and the most harm that can be
done is to crash a particular process or make internal Denial Of Service but we do not consider that
as CVE worthy and generally advisory worthy.

More details about it in our policy: https://github.com/apache/airflow/security/policy#is-this-really-a-security-vulnerability-

# Immediate response for self-XSS issues triggered by Authenticated users

Thanks for keeping Airflow secure.

We have discussed similar concerns in the past - and we consider such reports concerning those
kinds of issues as invalid. Unless you can provide a specific scenario where it can be exploited
and Confidentiality, Availability and Integrity of Airflow deployment are breached in a meaningful way,
we consider that as a regular issue and we encourage people like you to submit fixes via PR using
our regular GitHub contribution process. That's an easy way to become one of more than 2700
contributors and we encourage directly fixing such issues in PRs without even creating
GitHub Issues for them.

The reason for that is that Airflow is not publicly available software. When you run Airflow in an internal
network, the users of Airflow are known once authenticated and the most harm that can be done is to make
internal XSS to themselves, but we do not consider that as CVE worthy and generally advisory worthy.

More details about it in our policy: https://github.com/apache/airflow/security/policy#is-this-really-a-security-vulnerability-

# Positive Assessment response

Thanks again for keeping Airflow secure. We assessed your request
and we decided that this is a SEVERITY severity issue.

We followed https://github.com/apache/airflow/security/policy#how-do-we-assess-severity-of-the-issue- to
assess the severity). The CVE for this issue is CVE_ID and we expect it to be solved in next Airflow release.
Please monitor our announcements as explained in https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

# Negative Assessment response

Thanks again for keeping Airflow secure. We assessed your request and we decided that this is not a
CVE worthy issue.

HERE DETAILED EXPLANATION FOLLOWS

# DOS/RCE/Arbitrary read via Test Connection

Thanks for keeping things secure for airflow, but this request is invalid.

It is described in our model and the issue has been already addressed https://nvd.nist.gov/vuln/detail/CVE-2023-37379

We identified that test connection feature opens up various ways how users who have access to it could abuse
various kind of capabilities given by a various kinds of connections: RCE, arbitrary file read,
Denial of service and likely all kinds of capabilities that are often (in systems that are open-up to public
use, given to users who have no high privileges can be considered as a vulnerability).

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

Connection editing users have such capabilities. Our users are aware of that, and this is intended and we are not planning to do anything about it.

Actually the approach which we took where we make sure it's clear such capabilities are
available for "Connection Editing" user - is far more secure and safe than trying to address all
kinds of connections - because our users might have their own providers and connections, and fixing
"one" of the connections is not approaching the problem in a "systematic" way and gives false sense
of security - which is often worse than being aware that certain features are generally dangerous
when enabled, or that certain roles - when granted - give the users some insecure capabilities.
We chose the - far better in our opinion - approach where we not only disabled the test connection
by default but also clearly informed our users - specifically deployment managers, that the
"Connection Editing" role has potentially dangerous capabilities and users who have this role
should be highly trusted that they won't abuse it. This is both - more fair to our users and more
secure in general, because otherwise our users would not be aware of that and could give access to
the role to people who are not highly trusted (and they could abuse similar capabilities coming
from 100s of other connections - that are even not controlled by us, nor we could provide
any kinds of advisories for those.

Please consider a "Connection Editing" user similar to a "root" user having access to all the systems and
highly privileged, capable to perform RCE and similar with any of the systems, especially
when test connection is enabled.

Kindly ask you to consider that in your future research.

# When someone submits a media report

When submitting your report, please consider sending it in plain text format rather
than as an image or video file. Plain text allows for immediate access and straightforward
handling of the report's content, making it easier to process and analyze. Images or videos,
on the other hand, involve extra steps for extraction or transcription, which can slow down the review process.

By providing your report in plain text, you're not only simplifying its accessibility but also
contributing to quicker data processing. This streamlined approach enhances efficiency and
productivity in working with the information you've shared. Your cooperation in re-submitting
the report in plain text format would be greatly appreciated and will significantly expedite
our review process. Thank you for your understanding!

# Or an alternative response

While including a video or image might offer supplementary information, it's important to ensure that
all the content within these visuals is also provided in plain text. This allows for comprehensive
accessibility and easy referencing to the information presented in the multimedia content.

In instances where a video or image is attached, it's incredibly helpful if the details, data, or any
pertinent information shared within these files are also provided in plain text format. This enables
a seamless review and extraction of key points, guaranteeing that all information is readily
accessible and available for analysis.

Therefore, in addition to any multimedia files submitted, kindly ensure that all contained information
is also presented in plain text. This practice ensures that nothing crucial is missed and enables
a quicker and more efficient review process. Your cooperation in providing comprehensive
plain text details will be greatly appreciated. 

Thank you!
