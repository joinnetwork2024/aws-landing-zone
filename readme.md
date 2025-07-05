# 🚀 AWS Organizations Terraform Module

This module helps you provision a secure and scalable AWS multi-account environment using AWS Organizations. It supports:

- Organization creation
- Organizational Units (OUs)
- AWS account creation
- Delegated administrators
- Service access integrations (e.g., CloudTrail, AWS Config)
- Optional tagging and flexible structure design

---

## 📁 Module Structure

This module conditionally creates:

- An AWS Organization root
- One or more Organizational Units (OUs)
- AWS accounts within specific OUs
- Delegated administrators (optional)

Each resource is controlled via input variables. Use this module multiple times with different configurations to build a complete landing zone.

---

## ✅ Use Cases

- Landing zone bootstrapping
- AWS Control Tower alternatives
- Multi-account Dev/Security/Prod setups
- Delegated admin registration

---



