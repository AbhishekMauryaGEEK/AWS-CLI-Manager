# AWS CLI Manager

A modular, interactive Bash console for managing AWS infrastructure on top of the AWS CLI. It replaces long, flag-heavy `aws` commands with a guided, menu-driven workflow for EC2, S3, IAM, and VPC — while remaining a thin, inspectable wrapper around the official CLI.

<p align="left">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash-121011" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-linux%20%7C%20macOS-lightgrey" />
  <img alt="AWS CLI" src="https://img.shields.io/badge/aws--cli-v2-232f3e" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
  <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/AbhishekMauryaGEEK/AWS-CLI-Manager/ci.yml?branch=main" />
</p>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Authentication Workflow](#authentication-workflow)
- [Supported AWS Services](#supported-aws-services)
- [Feature Matrix](#feature-matrix)
- [Example CLI Screens](#example-cli-screens)
- [Security Considerations](#security-considerations)
- [Project Roadmap](#project-roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

AWS CLI Manager is an interactive terminal application that drives the AWS CLI through a single, unified menu. It is designed for developers, students, and operators who perform routine AWS tasks from the command line and want a faster, more guided alternative to memorizing command syntax, query expressions, and region flags.

The tool is organized as a set of self-contained service modules. A central entry point loads a shared core (authentication, session handling, region selection, environment checks) and then composes the EC2, S3, IAM, and VPC modules into a single management console.

AWS CLI Manager is intentionally scoped. It is not an infrastructure-as-code system and is not a replacement for the AWS Console, the AWS CLI, or Terraform. Every action maps directly to a real `aws` command, which keeps behavior transparent and predictable.

---

## Features

- **Unified console** — manage EC2, S3, IAM, and VPC from one menu.
- **Authenticated sessions** — interactive login/logout backed by AWS STS identity verification and session persistence.
- **Modular by service** — each AWS service is an isolated module that can evolve independently.
- **Guided workflows** — prompts for required inputs, sensible defaults, and confirmation gates for destructive actions.
- **Automatic environment setup** — detects the AWS CLI and offers to install it on Linux and macOS.
- **Multi-region support** — switch the active region at runtime.
- **Transparent operations** — every menu action is a thin wrapper around a documented `aws` command.

---

## Architecture Overview

AWS CLI Manager follows a **modular, single-responsibility architecture**. A shared `Core` layer provides cross-cutting concerns, and each AWS service lives in its own directory as an independent module. The top-level `main.sh` sources every module and `menu.sh`, runs pre-flight checks, and launches the console.

```
                        ┌────────────────────┐
                        │      main.sh       │  entry point
                        └─────────┬──────────┘
                                  │ sources
              ┌───────────────────┼────────────────────┐
              ▼                   ▼                    ▼
        ┌───────────┐      ┌────────────┐       ┌────────────┐
        │   Core    │      │  Service   │       │  menu.sh   │
        │  layer    │      │  modules   │       │ dispatch   │
        └───────────┘      └────────────┘       └────────────┘
         config             EC2  S3              main_menu
         install            IAM  VPC             ec2_menu / s3_menu
         auth                                    iam_menu / vpc_menu
         regions
         session
```

Each **service module** is built from the same set of responsibilities, which keeps the codebase predictable and makes new modules straightforward to add:

| Concern | Description |
|---------|-------------|
| Menu | An interactive submenu that lists operations and dispatches user input to functions. |
| CRUD operations | One function per AWS action (create, list, update, delete), each wrapping a single `aws` command. |
| Helpers | Shared formatting, prompts, and resource lookups used by the module. |
| Validation | Input checks, resource existence checks, and confirmation prompts before destructive actions. |
| Authentication integration | Operations run within an authenticated session established by the `Core` layer. |

This separation emphasizes **extensibility and maintainability**: a new service is added by creating a directory of small scripts and wiring its menu into `menu.sh`, without modifying existing modules.

---

## Repository Structure

```
AWS-CLI-Manager/
├── main.sh                     # Entry point: sources modules, runs pre-flight checks, starts the console
├── menu.sh                     # Top-level menu and per-service submenus
├── Core/
│   ├── config.sh               # Shared config, helpers (error_exit, pause), OS detection
│   ├── install.sh              # AWS CLI detection and installation (Linux, macOS)
│   ├── auth.sh                 # Credential verification (aws sts get-caller-identity)
│   ├── regions.sh              # Region selection
│   └── session.sh              # Login / logout / session load / session validation
├── EC2/
│   ├── create_instance.sh      # Guided instance creation (type, distro, AMI, key pair, SG)
│   ├── instances.sh            # List / details / start / stop / reboot / terminate / SSH
│   └── keypairs.sh             # Key pair creation and listing
├── S3/
│   └── buckets.sh              # Bucket and object operations
├── IAM/
│   └── users.sh               # Users, access keys, groups, membership, policies
├── VPC/
│   ├── vpcs.sh                 # VPC operations
│   ├── subnets.sh              # Subnet operations
│   ├── internet_gateway.sh     # Internet gateway operations
│   └── route_tables.sh         # Route table operations
├── .github/workflows/ci.yml    # Syntax check, ShellCheck, secret scan, structure check
├── LICENSE                     # MIT
└── README.md
```

---

## Requirements

| Requirement | Notes |
|-------------|-------|
| Bash | Scripts use `#!/bin/bash`. |
| AWS CLI v2 | The tool detects it and can install it on Linux/macOS if missing. |
| `jq` | Used to parse STS identity output during session handling. |
| `ssh` | Required for the EC2 "SSH Into Instance" feature. |
| `curl`, `unzip` | Used during AWS CLI installation on Linux. |
| AWS account | An account with credentials (access key ID / secret access key) and appropriate IAM permissions. |

> Operating against AWS incurs charges according to AWS pricing. You are responsible for all resources this tool creates. See [Security Considerations](#security-considerations).

---

## Installation

Clone the repository:

```bash
git clone https://github.com/AbhishekMauryaGEEK/AWS-CLI-Manager.git
cd AWS-CLI-Manager
```

Make the entry point executable:

```bash
chmod +x main.sh
```

Modules are sourced using relative paths, so run the tool **from the repository root**:

```bash
./main.sh
```

On first run, the tool will:

1. Verify that the AWS CLI is installed, and offer to install it if it is missing.
2. Verify that AWS credentials are configured (running `aws configure` if needed).
3. Load any existing session and prompt for a region.

---

## Usage

Start the console from the repository root:

```bash
./main.sh
```

The main menu shows the active session and exposes each service:

```
==============================
   AWS MANAGEMENT CONSOLE
==============================

Current User : Guest
Account      : N/A
Region       : ap-south-1

1. EC2
2. S3
3. IAM
4. VPC

5. Login
6. Logout
7. Change Region

0. Exit
```

Select a service to open its submenu, choose an operation, and follow the prompts. Destructive operations (for example, terminating an instance) require explicit confirmation before they run.

### Example: launch and connect to an EC2 instance

1. From the main menu, select **5** to log in (or ensure credentials are already configured).
2. Select **1** to open the EC2 menu.
3. Select **8** to create a key pair; it is saved locally as `<name>.pem` with `400` permissions.
4. Select **1** to create an instance — enter a name, choose an instance type, select the key pair, and pick a distribution.
5. Select **2** to list instances and copy the new instance ID.
6. Select **10** to SSH into the instance, providing the SSH user and the path to your `.pem` file.

---

## Authentication Workflow

Authentication and session state are handled by the `Core` layer (`Core/auth.sh`, `Core/session.sh`). The tool maintains an in-session identity and validates it against AWS STS rather than trusting locally stored credentials blindly.

```
  ┌──────────┐      login       ┌─────────────────────┐    valid    ┌──────────────────┐
  │  Guest   │ ───────────────▶ │  Write ~/.aws creds │ ──────────▶ │  Session Active  │
  │ session  │                  │  + STS validation   │             │  (user, account) │
  └──────────┘                  └─────────────────────┘             └──────────────────┘
       ▲                                  │ invalid                          │ logout
       │                                  ▼                                  │ (type LOGOUT)
       │                       restore previous creds                       │
       └──────────────────────────────────────────────────────────────────┘
```

| Step | Behavior |
|------|----------|
| Active session check | Login is blocked if a session is already active; the user must log out first. |
| Credential entry | Prompts for Access Key ID and a hidden Secret Access Key. |
| Empty input validation | Rejects empty access key or secret key before contacting AWS. |
| Credential backup | Backs up any existing `~/.aws/credentials` before writing new ones. |
| STS identity verification | Validates credentials with `aws sts get-caller-identity`. |
| Invalid credential handling | Restores the previous session (or clears credentials) when validation fails. |
| Session persistence | Resolves and stores the current user and account ID for the active session. |
| Session detection | Distinguishes root, IAM users, and the unauthenticated `Guest` state. |
| Logout confirmation | Requires typing `LOGOUT` to confirm; removes credentials while preserving region config. |

---

## Supported AWS Services

| Service | Scope |
|---------|-------|
| EC2 | Instance lifecycle, instance details, SSH access, and key pair management. |
| S3 | Bucket lifecycle and object upload, download, listing, and deletion. |
| IAM | Users, access keys, groups, group membership, and managed policy attachment. |
| VPC | VPCs, subnets, internet gateways, and route tables. |

---

## Feature Matrix

### EC2

| Category | Operations |
|----------|-----------|
| Instances | Create, List, Details, Start, Stop, Reboot, Terminate |
| Access | SSH Into Instance |
| Key Pairs | Create Key Pair, List Key Pairs |

Instance creation is guided: it supports `t2.micro` and `t3.micro` types, resolves the latest AMI for the chosen distribution at launch time (Amazon Linux 2023, Ubuntu 24.04 LTS, Ubuntu 22.04 LTS, Debian 12), uses the account's default VPC, and creates or reuses a security group named `ec2-manager-sg`.

### S3

| Category | Operations |
|----------|-----------|
| Buckets | Create Bucket, List Buckets, Delete Bucket |
| Objects | Upload Objects, Download Objects, List Objects, Delete Objects |

### IAM

| Category | Operations |
|----------|-----------|
| Users | Create User, List Users, Delete User |
| Access Keys | Create, List, Delete |
| Groups | Create, List, Delete |
| Membership | Add User to Group, Remove User from Group |
| Policies | Attach Policy, List Attached Policies, Detach Policy |

### VPC

| Category | Operations |
|----------|-----------|
| VPC | Create, List, Delete |
| Subnets | Create, List, Delete |
| Internet Gateway | Create, List, Attach, Detach, Delete |
| Route Tables | Create, List, Associate, Disassociate, Add Internet Route, Delete |

---

## Example CLI Screens

### EC2 menu

```
==============================
          EC2 MENU
==============================

1. Create Instance
2. List Instances
3. Instance Details
4. Start Instance
5. Stop Instance
6. Reboot Instance
7. Terminate Instance

------------------------------------------
KEY PAIRS
------------------------------------------
8. Create Key Pair
9. List Key Pairs

------------------------------------------
SETTINGS
------------------------------------------
10. SSH Into Instance

0. Exit
```

### IAM menu

```
==============================
          IAM MENU
==============================

-----USERS-------
1. Create User
2. List User
3. Delete User

----ACCESS KEY----
4. Create Access Key
5. List  Access Key
6. Delete Access Key

----IAM_GROUPS----
7. Create Group
8. List Group
9. Delete Group

----MEMBERSHIP----
10. Add User to Group
11. Remove User from Group

----POLICIES----
12. Attach Policies
13. List Attached Policies
14. Detach Policies
0. Back
```

### VPC menu

```
==============================
          VPC MENU
==============================

--------VPCS--------
1. Create VPC
2. List VPCs
3. Delete VPC

------SUBNETS-------
4. Create Subnet
5. List Subnets
6. Delete Subnet

---INTERNET GATEWAY---
7. Create Internet Gateway
8. List Internet Gateways
9. Attach Internet Gateway
10. Detach Internet Gateway
11. Delete Internet Gateway

----ROUTE TABLES----
12. Create Route Table
13. List Route Tables
14. Associate Route Table
15. Disassociate Route Table
16. Add Route
17. Delete Route Table

0. Back
```

---

## Security Considerations

Review this section before running the tool against any account you care about.

- **Principle of least privilege.** Use IAM credentials scoped to only the services and actions you intend to manage. Avoid using root credentials. Create a dedicated IAM user or role for the tool and grant the minimum permissions required for EC2, S3, IAM, and VPC operations you plan to perform.
- **IAM permissions.** Operations fail cleanly when permissions are missing, but the tool does not grant or audit permissions for you. Confirm that the active identity is authorized for the actions you select, especially IAM operations that can modify access.
- **AWS credentials.** Credentials are managed through the standard AWS CLI configuration (`~/.aws/credentials`). The login workflow backs up existing credentials before writing new ones and validates them with STS. `.env` and `.aws/` are listed in `.gitignore` — never commit credentials.
- **SSH key handling.** Creating a key pair writes a `.pem` file to the working directory with `400` permissions. Anyone with that file can access the corresponding instances. `*.pem` and `*.key` are gitignored; store private keys securely and never commit them.
- **Open SSH ingress.** EC2 instance creation uses a security group (`ec2-manager-sg`) that allows inbound TCP port 22 from `0.0.0.0/0`. This is convenient for getting started but is not appropriate for production. Restrict the ingress CIDR to trusted ranges for real use.
- **Destructive operations.** Actions such as terminating instances, deleting buckets, deleting IAM resources, and deleting VPC components permanently affect real resources. Destructive actions require explicit confirmation, but you remain responsible for their consequences.
- **Billing responsibility.** Every resource created through this tool may incur charges according to AWS pricing. Monitor and clean up resources you no longer need.

If you discover a security issue, please open an issue without including sensitive details, or contact the maintainer privately.

---

## Project Roadmap

The roadmap is organized so that each new capability is added as an independent module or a self-contained enhancement, consistent with the existing architecture. Items are aspirational and may change.

### Additional AWS services

| Service | Planned scope |
|---------|---------------|
| Security Groups | Standalone rule management and reuse. |
| Elastic IPs | Allocation, association, and release. |
| EBS | Volume creation, attachment, snapshots. |
| Auto Scaling | Launch templates and scaling groups. |
| Load Balancers | ALB/NLB target groups and listeners. |
| CloudWatch | Metrics, alarms, and log groups. |
| Lambda | Function deployment and invocation. |
| RDS | Database instance lifecycle. |
| CloudFormation | Stack management. |

### Tooling and platform

- Non-interactive CLI mode for scripting and automation.
- Resource search across services.
- Structured logging and a debug mode.
- Export results to JSON and CSV.
- Performance optimizations for listing and lookups.
- A plugin architecture for third-party service modules.

---

## Contributing

Contributions are welcome. Most changes fall into two categories: improving an existing module, or adding a new service module.

### Coding style

- Write portable Bash with `#!/bin/bash` and clear `[OK]` / `[INFO]` / `[ERROR]` status messages.
- Keep each menu action a thin, inspectable wrapper around a single `aws` command.
- Validate inputs and require confirmation before any destructive action.
- Match the formatting, naming, and prompt conventions of the surrounding code.

### Module structure

- Place each service in its own top-level directory.
- Split operations into small, single-responsibility scripts (CRUD, helpers, validation).
- Add the module's submenu to `menu.sh` and source its scripts from `main.sh`.
- Integrate with the `Core` session layer so operations run within an authenticated session.

### Testing expectations

- Ensure scripts pass `bash -n` (syntax check) and ShellCheck; the CI workflow runs both.
- Test changes against a real AWS account in a non-production region before opening a pull request, and note what you tested.
- Do not commit secrets. Private keys, `.env` files, and local AWS config must remain gitignored.

### Issues and pull requests

- **Issues** — describe the problem or proposal, the affected module, your environment (OS, AWS CLI version), and steps to reproduce where applicable.
- **Pull requests** — keep them focused and reasonably small, describe the change and the module it affects, and include the commands you ran to verify it.

---

## License

This project is licensed under the [MIT License](LICENSE).
