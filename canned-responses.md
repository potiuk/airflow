<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Confirmation of receiving the report](#confirmation-of-receiving-the-report)
- [Invalid automated report](#invalid-automated-report)
- [Not an issue, please submit it](#not-an-issue-please-submit-it)
- [Parameter injection to operator or hook](#parameter-injection-to-operator-or-hook)
- [DOS issues triggered by Authenticated users](#dos-issues-triggered-by-authenticated-users)
- [When someone claims Dag Author provided "user input" is dangerous](#when-someone-claims-dag-author-provided-user-input-is-dangerous)
- [Image scan results](#image-scan-results)
- [Immediate response for self-XSS issues triggered by Authenticated users](#immediate-response-for-self-xss-issues-triggered-by-authenticated-users)
- [Positive Assessment response](#positive-assessment-response)
- [Negative Assessment response](#negative-assessment-response)
- [Automated scanning results](#automated-scanning-results)
- [DOS/RCE/Arbitrary read via Provider's Connection configuration](#dosrcearbitrary-read-via-providers-connection-configuration)
- [When someone submits a media report](#when-someone-submits-a-media-report)
- [Or an alternative response](#or-an-alternative-response)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Confirmation of receiving the report

Thanks for the report and for trying to make Airflow secure.

We registered the issue. This is our initial response, you can expect that we will come back to you with the result of our assessment
according to our security policy: https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

# Invalid automated report

This is an invalid, automated report. that has no substance,

The behaviour you explain is by design and described in our Security Model https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html
The sent report does not follow our security policy (https://github.com/apache/airflow/security/policy), does not refer to our security model, and does not explain how it is violated.

Please elaborate and refer to our security model, explaining how it is violated. We will be happy to discuss this with the person who verified and reviewed the reports. Please read and understand the model and the policy we have (according to our policy).

Multiple such reports will result in blacklisting those accounts. We will immediately close reports from blacklisted entities without reading them.

# Not an issue, please submit it

Thanks for attempts to make Airflow secure, but this report is invalid.

This is not a security vulnerability, this does not violate Confidentiality, Availability and Integrity and the Role of the user involved already has more capabilities than what you describe.

Our security team deals only with security issues.

But the approach you suggested is a good idea to improve Airflow in general. Feel absolutely free to submit it via regular contribution pattern; PRs as usual are most welcome.


# Parameter injection to operator or hook

Thanks for making Airflow secure, but this is not a vulnerability.
Do you have an example where we explicitly recommend using this feature in the described way—i.e., by passing table names or similar parameters from the UI directly into a hook?

If not, we consider this report invalid and not a security vulnerability. If you are interested in improving Airflow's security posture, feel free to create a public PR to do so. We will greatly appreciate it.

More explanation:

When you write Airflow DAGs, you use Python and can pass any input parameter to any of the underlying code. Airflow Hooks are a low-level interface to the integration Airflow exposes. To connect this low-level interface with UI input, DAG authors must write DAGs, tasks, or operators to pass those values. DAG authors - according to the security model https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#capabilities-of-dag-authors  can execute arbitrary code and connect with arbitrary credentials to any system Airflow interacts with. As programmers, they are responsible for not passing untrusted user input to the operators.

To exploit the parameter entry by users, the DAG needs to be written in a specific way and pass the user input to the operator, which requires explicit Dag Author action. Similarly, just as you can pass an "input parameter" to the Bash operator and execute arbitrary code, you can pass any other parameters to any other hook inputs. It is up to the DAG author to ensure parameters are passed safely. The only reason some past cves (like `CVE-2025-50213` or `CVE-2025-27018` were assigned a (low) severity was due to official documentation that suggested a pattern that could lead to misuse. I
f no such guidance or documentation exists in the case you described, there’s no vulnerability (but we stil encourage you to submit the PR as a regular contribution process).

# DOS issues triggered by Authenticated users

Thanks for keeping Airflow secure.

We have discussed similar concerns in the past and consider such generic reports concerning those
kinds of issues invalid. Unless you can provide a specific scenario where it can be exploited and
Confidentiality, Availability, and Integrity of Airflow deployment are breached in a meaningful way,
we consider that as a regular issue, we encourage people like you to submit fixes via PR using our
regular GitHub contribution process. That's an easy way to become one of more than 2700
contributors, and we encourage directly fixing such issues in PRs without even creating GitHub Issues for them.

The reason for that is that Airflow is not publicly available software. When you run Airflow in an
internal network, the users of Airflow are known once authenticated, and the most harm that can be
done is to crash a particular process or make an internal Denial Of Service, but we do not consider that
as CVE-worthy and generally advisory-worthy.

More details about it in our policy: https://github.com/apache/airflow/security/policy#is-this-really-a-security-vulnerability-

# When someone claims Dag Author provided "user input" is dangerous

You need to first look at the Security Model of ours and read about Dag Author capabilities:
https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html.

In your report a form of "User controlled input" is used, but you need to explain
**which** User Role controls it, otherwise it ambiguous and does not take the model into account.

Dag Author can generally modify any code and execute any python code on the worker and have access to
all credentials. So they already can do a lot, and they are also responsible to make sure that they
are not passing any "other user roles" controlled input to a function that is potentially dangerous.

With great powers come great responsibilities and Dag Authors have both.

If other user roles can (without Dag Author deliberately passing such input) can pass such input,
then we could consider it as a potential vulnerability. Dag Author can make a lot of harm if they
are not careful programmers, and this is clearly explained in our model, including some remediation
(such as mandatory code reviews) that can be put in place by the Deployment Manager to mitigate such risks.

Unless you provide a POC where such scenario happens, and Dag Author does not have to deliberately pass
other user input to a dangerous function - we consider this report as invalid.

Often, such a dangerous function could be improved by sanitizing things by default, but there are many
dangerous functions - even in the standard library that assume that whoever uses them will do it with
care and we cannot sanitize all of them by default. So if you think anything from your report indicates
that there is a possible security improvement, we encourage you to follow the regular contribution
process and submit a PR with the improvement you think is needed or open a public issue about it - like
more than 3600 other contributors. If your goal is to improve the security of Airflow, this is the most
pragmatic way to do it.

Thank you for your understanding - our security team is volunteer-driven and and the "behind the
scenes" process is only taking care of issues that cannot be public  and that are "real" security issues,
otherwise we might not be able to focus on real issues with appropriate priority.

Your help in making Airflow secure is highly appreciated, but in this case (unless you can provide a
POC proving otherwise) - this is not a security issue and public / usual way of contribution is the
only appropriate way of moving forward with it.

If you are using any AI tooling to generate such a report, we strongly recommend you feed it with our model
and this response and improve the way how it reports such issues. Ideally such AI tool should not only
understand that this is not a security issue, but also it should be able to prepare a PR for you that
you could review and submit after reviewing and making sure that you cannot provide a POC that
goes beyond the security model we have - which we heartily recommend you to do if you want to
improve security of Airflow.


# Image scan results

As explained in our security policy https://github.com/apache/airflow/security/policy#what-should-be-and-should-not-be-reported-
you should not use that email for such requests. Please do not use it in the future for such requests:

> Specifically, we will ignore results of security scans that contain a list of dependencies of Airflow with dependencies
> in Airflow Docker reference image - there is a page that describes how the Airflow reference Image is fixed at release
> time and providing helpful instructions explaining how you can build your own image and manage dependencies of Airflow in your own image.

If you want to deal with security issues reported by your scanners https://airflow.apache.org/docs/docker-stack/index.html#fixing-images-at-release-time
describes what to do in this case. Generally you have three options:

1) Build your own custom image following the examples we share there - using the latest base
   image and possibly bumping dependencies you want to bump. There are quite a few examples there when you follow the links.

2) Wait for a new version of Airflow and upgrade to it. Airflow images are updated to latest "non-conflicting" dependencies and
   use latest "base" image at release time, so what you have in the reference images at the moment we publish the image / release
   the version is what is "latest and greatest" available at the moment with the base platform we use (debian bookworm is the reference image we use).

3) If the base platform we use (currently debian-bookworm) does not contain the latest versions you want and you want to use other base images,
   you can take a look at what system dependencies are installed in the latest Dockerfile of airflow and take inspiration from it and build your
   own image (or copy the dockerfile and modify it as you see fit) https://github.com/apache/airflow/blob/main/Dockerfile

This gives you all the flexibility you need. You can rely on Airlow bumping to latest, non-conflicting 3rd-party dependency versions regularly -
with every release, so one of the strategies you can take to keep your Airflow secure is to engage in early testing of RC candidates and
upgrading to newer airlfow releases as soon as they happen.

Also if you think that something is not false positive - we encourage you to contribute back by analysing such  scan reports and trying
to come up with exploitation scenarios - and report it here for other people who might be looking at it. If you have an exploitation
scenario you can report it privately following our security policy https://github.com/apache/airflow/security/policy - this email is
there if you will find a way how to exploit third-party dependency vulnerability in airflow, and all the volunteer maintainers highly
appreciate efforts of our commercial users to report such exploitable vulnerabilities (after analysing them) as a way to contribute
back for the community that makes the free software available for you at no charge.


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
assess the severity. The CVE for this issue is CVE_ID, and we expect it to be solved in the next Airflow release.
Please monitor our announcements as explained in https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

Thank you for your contribution to the CVE assessment. Could you please let us know how you would like to be credited for your work?

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


# DOS/RCE/Arbitrary read via Provider's Connection configuration

Thanks for keeping things secure for Airflow, but this request is invalid.

We no longer consider those kinds of issues as security issues - feel free to create an issue to change the behaviour of
the connection or - even better - make a PR to change it. We will be happy to review and merge it.

It is described in our model, and the general issue which was actually even more exploitable with the
"test connection" feature has already been addressed in https://nvd.nist.gov/vuln/detail/CVE-2023-37379

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

You can read more about it in Airflow's security model https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#connection-configuration-users

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
