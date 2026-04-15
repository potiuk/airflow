<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Confirmation of receiving the report](#confirmation-of-receiving-the-report)
- [Invalid report about Simple Auth Manager with multiple issues](#invalid-report-about-simple-auth-manager-with-multiple-issues)
- [Invalid automated report](#invalid-automated-report)
- [Sending multiple issues in consolidated report](#sending-multiple-issues-in-consolidated-report)
- [Not an issue, please submit it](#not-an-issue-please-submit-it)
- [Parameter injection to operator or hook](#parameter-injection-to-operator-or-hook)
- [DoS issues triggered by Authenticated users](#dos-issues-triggered-by-authenticated-users)
- [When someone claims Dag author-provided "user input" is dangerous](#when-someone-claims-dag-author-provided-user-input-is-dangerous)
- [Image scan results](#image-scan-results)
- [Immediate response for self-XSS issues triggered by Authenticated users](#immediate-response-for-self-xss-issues-triggered-by-authenticated-users)
- [Positive Assessment response](#positive-assessment-response)
- [Negative Assessment response](#negative-assessment-response)
- [Automated scanning results](#automated-scanning-results)
- [DoS/RCE/Arbitrary read via Provider's Connection configuration](#dosrcearbitrary-read-via-providers-connection-configuration)
- [When someone submits a media report](#when-someone-submits-a-media-report)
- [Or an alternative response](#or-an-alternative-response)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Confirmation of receiving the report

Thanks for the report and for trying to make Airflow secure.

We have registered the issue. This is our initial response; you can expect that we will come back to you with the result of our assessment
according to our security policy: https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

# Invalid report about Simple Auth Manager with multiple issues

Thank you for the report. We cannot accept it, for two reasons.

First, behaviour observed against Simple Auth Manager is explicitly out of scope for our security process. This is documented in our Security Model under "Simple Auth Manager": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#simple-auth-manager. Simple Auth Manager is intended only for development and testing, and a banner stating this appears every time a user logs in.

Second, our security policy requires that each report cover a single issue. Reports that bundle multiple vulnerabilities into one submission do not meet this requirement and are not reviewed. See https://github.com/apache/airflow/security/policy.

If you would like to propose improvements to Simple Auth Manager outside the scope of a security report, we welcome contributions through the standard process — Airflow has thousands of contributors. Contributions need to follow our contribution guidelines: https://github.com/apache/airflow/blob/main/contributing-docs/README.rst.

Before submitting any further reports, please read the security policy and the security model in full and ensure your submissions meet the requirements. Due to the volume of reports that do not, accounts that repeatedly ignore the policy are added to a deny list, after which their future reports are not read.

# Invalid automated report

Thank you for the report. We cannot accept it in its current form.

The behaviour described is by design. Automated scanning results without human verification are explicitly out of scope for our security process — see "Automated scanning results without human verification" in our Security Model: https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#automated-scanning-results-without-human-verification.

Our security policy (https://github.com/apache/airflow/security/policy) requires every report to reference the security model and explain specifically how it is violated. This report does not, so we are unable to review it.

If, after reading the security model, you still believe there is a vulnerability, please resubmit with a clear, human-verified explanation of how the model is violated. We will be glad to continue the discussion with the reviewer once that explanation is provided.

Please note that accounts that repeatedly send reports which do not meet the policy are added to a deny list, after which their future reports are closed without being read.

# Sending multiple issues in consolidated report

Thank you for the report. We cannot review it, as it does not meet the requirements of our security policy: https://github.com/apache/airflow/security/policy.

Every report sent to this address must:

* cover a single issue per email thread,
* be verified by a human against our Security Model,
* include a detailed, easy-to-reproduce Proof of Concept (PoC) that demonstrates how the issue violates our model (https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html), including the roles involved and the attack scenario.

If, after verifying each finding manually against the policy, you still consider any of the reported issues to be real vulnerabilities, please resubmit them as separate reports — one issue per thread, human-verified against the model, and each accompanied by a clear, easy-to-reproduce PoC. We will review any resubmission that meets these requirements.

Accounts that repeatedly send reports which do not meet the policy, despite being aware of the expectations, are added to a deny list and their reports are marked as spam. Please take the time to review the model carefully and explain the violation clearly before submitting.

# Not an issue, please submit it

Thank you for trying to make Airflow more secure. We have reviewed the report and this is not a security vulnerability: it does not violate Confidentiality, Availability, or Integrity, and the role of the user involved already has more capabilities than what you describe.

Our security team handles only security issues, so we are not able to take this further through this channel.

That said, the improvement you suggest is a reasonable idea for Airflow in general. We would welcome it as a regular contribution — please submit it via the standard process, where PRs are always welcome.


# Parameter injection to operator or hook

Thank you for the report. We do not consider this a vulnerability.

Dag author code passing unsanitized input to operators and hooks is explicitly out of scope for our security process. The full rationale — that Dag authors can already execute arbitrary code and are responsible for how input reaches operators and hooks — is documented in our Security Model:

* "Dag author code passing unsanitized input to operators and hooks": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#dag-author-code-passing-unsanitized-input-to-operators-and-hooks
* "Capabilities of Dag authors": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#capabilities-of-dag-authors

For this to be treated as a vulnerability, you would need to point to an example where our official documentation explicitly recommends using this feature in the way you described — i.e., by passing table names or similar parameters from the UI directly into a hook. The reason a few past CVEs (such as `CVE-2025-50213` or `CVE-2025-27018`) were assigned a (low) severity is that our official documentation suggested a pattern that could lead to misuse. Where no such guidance exists, there is no vulnerability.

If you would like to improve Airflow's security posture in this area, we would welcome a public PR through the regular contribution process.

# DoS issues triggered by Authenticated users

Thank you for the report and for your interest in Airflow's security.

Denial of Service by authenticated users is explicitly out of scope for our security process. The rationale — that Airflow is not intended to be publicly exposed and that authenticated users are known — is documented in our Security Model under "Denial of Service by authenticated users": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#denial-of-service-by-authenticated-users.

For us to treat this as a vulnerability, the report would need to include a specific scenario in which Confidentiality, Availability, or Integrity of an Airflow deployment is breached in a meaningful way beyond what the security model already covers. Without that, it is a regular issue.

We would welcome a fix through the regular GitHub contribution process — no GitHub issue is needed first — and this is a straightforward way to join the thousands of Airflow contributors.

More details are in our policy: https://github.com/apache/airflow/security/policy#is-this-really-a-security-vulnerability-

# When someone claims Dag author-provided "user input" is dangerous

Thank you for the report. Before we can consider it, please review the relevant chapters of our Security Model:

* "Capabilities of Dag authors": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#capabilities-of-dag-authors
* "Dag authors executing arbitrary code": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#dag-authors-executing-arbitrary-code
* "Dag author code passing unsanitized input to operators and hooks": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#dag-author-code-passing-unsanitized-input-to-operators-and-hooks
* "Limiting Dag author capabilities" (mitigations available to the Deployment Manager): https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#limiting-dag-author-capabilities

Your report refers to "user-controlled input", but to assess it against the model we need to know **which** user role controls the input. Without that, the report is ambiguous and cannot be evaluated against our model.

As the model explains, a Dag author already has the capability to execute arbitrary code and access all credentials, so a Dag author deliberately routing untrusted input into a dangerous call is not a vulnerability in Airflow. A vulnerability would only exist if another user role could cause such input to reach a dangerous function without the Dag author deliberately passing it through.

For this reason, we are unable to treat this as a security issue unless you provide a PoC showing a scenario in which the Dag author does not have to deliberately pass other users' input into a dangerous function.

If your report points to a concrete improvement — for example, sanitising input to a specific function by default — the right path is the regular contribution process: open a public issue or submit a PR, as thousands of contributors have done before you.

Our security team is volunteer-driven, and the private process is reserved for issues that genuinely cannot be discussed in public and that meet our definition of a security vulnerability. Handling reports that do not meet those criteria through this channel would prevent us from giving real issues the attention they need.

If you use AI tooling to help prepare reports, please feed it our Security Model and this response so that it can recognise when a finding is not a security issue and, ideally, help you prepare a PR for the regular contribution process instead.


# Image scan results

Thank you for the report. Third-party dependency scan results against the Airflow Docker reference image are explicitly out of scope for our security process. This is documented in our Security Model under "Third-party dependency vulnerabilities in Docker images": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#third-party-dependency-vulnerabilities-in-docker-images, and in our security policy: https://github.com/apache/airflow/security/policy#what-should-be-and-should-not-be-reported-.

Please do not use this address for such requests in the future:

> Specifically, we will ignore results of security scans that contain a list of dependencies of Airflow alongside dependencies
> in the Airflow Docker reference image — there is a page that describes how the Airflow reference image is fixed at release
> time and provides helpful instructions explaining how you can build your own image and manage the dependencies of Airflow in it.

If you want to deal with security issues reported by your scanners, https://airflow.apache.org/docs/docker-stack/index.html#fixing-images-at-release-time
describes what to do in this case. Generally, you have three options:

1) Build your own custom image following the examples we share there — using the latest base
   image and possibly bumping any dependencies you want to bump. There are quite a few examples available once you follow the links.

2) Wait for a new version of Airflow and upgrade to it. Airflow images are updated to the latest "non-conflicting" dependencies and
   use the latest "base" image at release time, so what you have in the reference images at the moment we publish the image /
   release the version is the "latest and greatest" available at that moment with the base platform we use (Debian Bookworm is the
   reference image we use).

3) If the base platform we use (currently Debian Bookworm) does not contain the latest versions you want, and you want to use other base images,
   you can take a look at what system dependencies are installed in the latest Airflow Dockerfile, take inspiration from it, and build your
   own image (or copy the Dockerfile and modify it as you see fit): https://github.com/apache/airflow/blob/main/Dockerfile

This gives you all the flexibility you need. You can rely on Airflow bumping to the latest, non-conflicting third-party dependency versions
regularly — with every release — so one of the strategies you can take to keep your Airflow secure is to engage in early testing of RC
candidates and upgrade to newer Airflow releases as soon as they are released.

Also, if you think that something is not a false positive, we encourage you to contribute back by analysing such scan reports and trying
to come up with exploitation scenarios — and reporting them here for other people who might be looking at the same issues. If you have an
exploitation scenario, you can report it privately following our security policy: https://github.com/apache/airflow/security/policy. That
email address is there for cases when you find a way to exploit a third-party dependency vulnerability in Airflow, and all the volunteer
maintainers highly appreciate the efforts of our commercial users to report such exploitable vulnerabilities (after analysing them) as a way
to contribute back to the community that makes the free software available to you at no charge.


# Immediate response for self-XSS issues triggered by Authenticated users

Thank you for the report and for your interest in Airflow's security.

Self-XSS by authenticated users is explicitly out of scope for our security process. The rationale — that Airflow is not intended to be publicly exposed, that authenticated users are known, and that the worst impact is a user attacking themselves — is documented in our Security Model under "Self-XSS by authenticated users": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#self-xss-by-authenticated-users.

For us to treat this as a vulnerability, the report would need to include a specific scenario in which the Confidentiality, Availability, or Integrity of an Airflow deployment is breached in a meaningful way beyond what the security model already covers. Without that, it is a regular issue.

We would welcome a fix through the regular GitHub contribution process — no GitHub issue is needed first — and this is a straightforward way to join the thousands of Airflow contributors.

More details are in our policy: https://github.com/apache/airflow/security/policy#is-this-really-a-security-vulnerability-

# Positive Assessment response

Thanks again for keeping Airflow secure. We have assessed your request
and decided that this is a SEVERITY severity issue.

We followed https://github.com/apache/airflow/security/policy#how-do-we-assess-severity-of-the-issue- to
assess the severity. The CVE for this issue is CVE_ID, and we expect it to be fixed in the next Airflow release.
Please monitor our announcements as explained in https://github.com/apache/airflow/security/policy#what-happens-after-you-report-the-issue-

Thank you for your contribution to the CVE assessment. Could you please let us know how you would like to be credited for your work?

# Negative Assessment response

Thanks again for keeping Airflow secure. We assessed your request, and we decided that this is not a
CVE-worthy issue.

HERE DETAILED EXPLANATION FOLLOWS

# Automated scanning results

Thank you for the report. We appreciate the intent, but this address is not the right place for automated scanning results. Automated scanning results without human verification are explicitly out of scope for our security process — see "Automated scanning results without human verification" in our Security Model: https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#automated-scanning-results-without-human-verification, and our security policy: https://github.com/apache/airflow/security/policy.

We run our own automated tooling to detect and prevent issues, and our security team manages any findings that come out of it.

For a report sent to this address to be reviewed, it must be verified by a human on your side and include a reproducible scenario that demonstrates how the Airflow Security Model is actually compromised. We are glad to review reports that meet these requirements; please ensure that any future submissions do.

Also note that the Apache Software Foundation runs its own CVE disclosure and publication process, so any CVE we issue will reach you through that channel. We review all such reports as part of that process.


# DoS/RCE/Arbitrary read via Provider's Connection configuration

Thank you for the report. We do not consider this a security issue, and we are not able to take it further through the security process.

The capabilities exposed by connection configuration — including RCE, arbitrary file read, Denial of Service, and similar — are intentional and are documented in our Security Model:

* "Connection configuration users": https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#connection-configuration-users
* "Connection configuration capabilities" (explicitly out of scope): https://airflow.apache.org/docs/apache-airflow/stable/security/security_model.html#connection-configuration-capabilities

The broader class of issues — which was in fact more exploitable through the "test connection" feature — was already addressed in CVE-2023-37379 (https://nvd.nist.gov/vuln/detail/CVE-2023-37379) and in Airflow 2.7.0, by disabling test connection by default and by making the risk explicit in the security model and the release notes.

Please treat a "Connection Editing" user as equivalent to a "root" user on every system Airflow connects to — highly privileged and capable of RCE and similar actions on any connected system, especially when test connection is enabled. We ask that you take this model into account in future research.

If you would like to propose a specific change to connection behaviour outside the scope of a security report, we would welcome a public issue or a PR through the regular contribution process.

# When someone submits a media report

When submitting your report, please consider sending it in plain-text format rather
than as an image or video file. Plain text allows for immediate access and straightforward
handling of the report's content, making it easier to process and analyze. Images and videos,
on the other hand, involve extra steps for extraction or transcription, which can slow down the review process.

By providing your report in plain text, you are not only making it more accessible but also
contributing to quicker processing. This streamlined approach enhances efficiency and
productivity when working with the information you share. Your cooperation in re-submitting
the report in plain-text format would be greatly appreciated and will significantly expedite
our review process. Thank you for your understanding!

# Or an alternative response

While including a video or image might offer supplementary information, it is important to ensure that
all the content within these visuals is also provided in plain text. This allows for comprehensive
accessibility and easy referencing of the information presented in the multimedia content.

When a video or image is attached, it is incredibly helpful if the details, data, or any
pertinent information shared within these files are also provided in plain-text format. This enables
seamless review and extraction of key points, guaranteeing that all information is readily
accessible and available for analysis.

Therefore, in addition to any multimedia files submitted, kindly ensure that all of the contained information
is also presented in plain text. This practice ensures that nothing crucial is missed and enables
a quicker and more efficient review process. Your cooperation in providing comprehensive
plain-text details will be greatly appreciated.

Thank you!
