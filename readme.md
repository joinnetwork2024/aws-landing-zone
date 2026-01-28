# 🛡️ AWS Organizations Terraform Module — Multi-Account Governance Foundation

---

## 🚀 Overview

This Terraform module provides a **secure, scalable foundation for AWS multi-account environments** using **AWS Organizations**. It is designed to support **landing zone architectures** by codifying account structure, organizational boundaries, and governance controls directly in Infrastructure-as-Code.

The module enables teams to consistently provision and manage:

* AWS Organizations
* Organizational Units (OUs)
* Multiple AWS accounts
* Delegated administrator roles
* Service access integrations

It is intended to be a **core building block** for enterprise-grade AWS landing zones.

---

## 🎯 What This Module Solves

Managing AWS Organizations manually does not scale and leads to inconsistent governance. This module allows you to:

* Standardize multi-account creation and hierarchy
* Enforce organizational boundaries through OUs
* Enable delegated administration for security and platform services
* Automate landing zone bootstrapping using Terraform
* Maintain auditability and version control over org-level changes

All governance decisions are expressed declaratively in code.

---

## 🧠 Core Capabilities

### 🏗 AWS Organization Management

The module can conditionally create and manage:

* An AWS Organization root
* One or more Organizational Units (OUs)
* AWS accounts mapped to specific OUs

This allows flexible designs ranging from simple dev/prod splits to complex enterprise hierarchies.

---

### 🧩 Delegated Administration

Supports registering **delegated administrators** for AWS services such as:

* AWS Config
* CloudTrail
* Security services

Delegation enables centralized governance while allowing service ownership to remain clearly defined.

---

### 🔐 Service Access Integrations

The module can enable AWS service access at the organization level, ensuring required services are available across accounts while maintaining centralized control.

---

## 📂 Module Structure & Usage

This module is **fully driven by input variables** and conditionally creates resources based on configuration.

It can be invoked multiple times with different inputs to construct a complete landing zone, including:

* Separate OU trees (e.g. Dev, Staging, Prod)
* Dedicated Security or Shared Services accounts
* Environment-specific account ownership

This design promotes **reuse, composability, and clarity**.

---

## ✅ Common Use Cases

* AWS Landing Zone bootstrapping
* Custom alternatives to AWS Control Tower
* Multi-account Dev / Staging / Prod environments
* Centralized security and logging accounts
* Delegated administrator registration

---

## 🛠 Terraform Notes

When working with policy documents or templates:

* `file()` reads a file as a **static string** (no variable interpolation)
* `templatefile()` reads a file and **injects variables** into it

Use `templatefile()` when generating SCPs, IAM policies, or configuration files that require dynamic values.

---

## 🧭 How This Fits in a Landing Zone

This module typically acts as the **organizational control plane** in a landing zone architecture:

* Defines *where* accounts live (OUs)
* Defines *who* owns services (delegated admins)
* Enables *what* services can operate org-wide

Higher-level infrastructure (networking, security tooling, workloads) should be layered on top using environment-specific modules.

---

📍 Architecture Diagram

OU hierarchy

Accounts per environment

Delegated admins & trust relationships

📍 Terraform Module Layout

Which modules create which resources

How environments are structured

📍 Deployment Steps

Setup pre-reqs (AWS creds, Terraform init, backends)

How to run each environment

📍 Trade-offs & Assumptions
Examples:

Using Terraform vs AWS Control Tower best practices

Delegated admin risks vs central control

SCP scope and implications

📍 Link to deployed resources

AWS Org info

SCP attachments

OU/account IDs

CloudTrail and security services once deployed


# AWS Landing Zone – Organizational Control Plane for Governed AI/ML Workloads

---

## Overview

This Terraform module establishes a **secure, multi-account AWS Organizations foundation** – the **control plane** for isolating and governing AI/ML workloads. It codifies account structure, Organizational Units (OUs), and delegated administration to enforce boundaries across the AI/ML lifecycle (Data, Training, Registry, Deployment, Inference).

Designed for **MLSecOps/AIOps architectures**, it supports:
* Isolation of sensitive AI workloads (e.g., data science sandboxes, secure model registries)
* Centralized security governance (delegated admins for GuardDuty, Config)
* Integration with Policy-as-Code (OPA/Rego) for pre-deployment enforcement

This is a core component of a production-grade AI governance portfolio.

---

## AI/ML Governance Context

In AI/ML platforms, infrastructure must enforce security at the **organizational level**:
- **Data Stage**: Isolate raw telemetry/training data accounts to prevent exfiltration/poisoning.
- **Training Stage**: Dedicated accounts for GPU-heavy experiments with cost/quota controls.
- **Registry Stage**: Secure accounts for model artifacts (signing, vulnerability scans).
- **Multi-Tenant Risks**: Account boundaries contain breaches (e.g., compromised data scientist → no lateral movement to prod inference).

This landing zone provides the **account isolation layer**, complemented by Rego policies (in linked `multi-cloud-secure-tf` repo) validating workload deployments.

---

## What This Module Solves for AI/ML Security

Manual org management leads to inconsistent isolation and governance drift. This module enables:
* Standardized multi-account hierarchy for AI workloads
* OU-based segmentation (e.g., Sandbox OU for experiments, Production OU for inference)
* Delegated administration for MLSecOps tools (GuardDuty for SageMaker, Config drift detection)
* Auditability via IaC – version-controlled boundaries explainable to auditors

Mitigates key risks: Data Poisoning (isolated sandboxes), Model Theft (secure registry accounts), Inference Abuse (OU-scoped quotas).

---

## Core Capabilities

### AWS Organization Management
* Conditional creation of Organization root, OUs, and accounts
* Flexible hierarchies (e.g., Workload OU with child OUs: IoT, Training, Inference)

### Delegated Administration
* Register delegated admins for security services (GuardDuty, Config, Security Hub) – centralized threat detection for SageMaker/IoT telemetry.

### Service Access Integrations
* Org-wide enablement of AI services (SageMaker, IoT Core) with controlled access.

---

## Module Structure & Usage

Fully variable-driven for composability. Invoke multiple times to build environment-specific trees (dev, staging, prod).

Example: Deploy IoT telemetry workload in isolated "iot-workload" account under Workloads OU.

---

## Integration with Policy-as-Code (MLSecOps Control Plane)

This landing zone is the **organizational boundary**; governance is enforced via OPA/Rego in CI/CD :
* Pre-deployment validation of Terraform plans for AI services (e.g., deny public SageMaker endpoints in prod accounts).
* Cross-account checks (e.g., model endpoints only in Production OU).

Example Rego (aiops.landing_zone.rego – proposed addition):
```rego
package x.landing_zone

# Account Isolation: AI training accounts MUST be in dedicated OU
deny[msg] {
  account := input.planned_values.aws_organizations_account[_]
  contains(account.tags[_], "workload:training")
  not endswith(account.parent_id, "ou-workloads")  # Enforce OU placement
  msg := "Training accounts (high GPU risk) MUST reside in Workloads OU – enforces isolation to prevent cost explosion/lateral movement (MITRE ATLAS: Resource Hijacking)."
}


## 📜 License

MIT License

---

**Use this module to establish clear ownership, enforce governance, and scale AWS securely with Terraform.**

