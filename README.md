# AWS CLI Manager

> A modular, menu-driven AWS infrastructure management tool built on top of the AWS CLI.

<!-- Badges — replace the placeholders below with live badge URLs (e.g. shields.io) once available. -->
<p align="left">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash-121011" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-linux%20%7C%20macOS-lightgrey" />
  <img alt="Status" src="https://img.shields.io/badge/status-early%20development-orange" />
  <img alt="License" src="https://img.shields.io/badge/license-TBD-blue" />
  <!-- <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/<owner>/<repo>/ci.yml" /> -->
  <!-- <img alt="Release" src="https://img.shields.io/github/v/release/<owner>/<repo>" /> -->
</p>

---

## Table of Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Architecture](#architecture)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Screenshots](#screenshots)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## Overview

**AWS CLI Manager** is a collection of Bash scripts that wrap the AWS CLI behind
an interactive, numbered menu. Instead of remembering long `aws ec2 ...`
commands and their flags, you launch a single entry point and drive common AWS
operations through prompts.

The project is organized by AWS service. Each service lives in its own directory
and exposes a self-contained menu. The first implemented service is **EC2**;
additional services (S3, IAM, VPC) are planned and slot into the same structure
without changing how existing modules work.

This is an early-stage tool intended for developers, students, and operators who
want a faster, more guided way to perform routine AWS tasks from the terminal.
It does not replace the AWS CLI, Terraform, or the AWS Console — it sits on top
of the AWS CLI and assumes you already have (or are willing to create) AWS
credentials.

---

## Motivation

The AWS CLI is powerful but verbose. Routine actions — launching an instance,
finding the right AMI for a distribution, opening SSH, listing key pairs —
require remembering command names, query expressions, filters, and region flags.

AWS CLI Manager exists to:

- **Reduce friction** for everyday operations by replacing memorized commands
  with guided prompts.
- **Encode sensible defaults** (e.g. resolving the latest AMI for a chosen
  distribution, creating a reusable security group) so common tasks work
  out of the box.
- **Stay transparent** — every action is a thin wrapper around a real `aws`
  command, so the behavior is inspectable and predictable.
- **Grow by service** — a modular layout means new AWS services can be added
  as independent modules rather than as edits to a monolithic script.

It is deliberately scoped. It is not a configuration-management or
infrastructure-as-code system; it is an interactive convenience layer over the
AWS CLI.

---

## Architecture

The repository is structured **one directory per AWS service**. Each service
directory contains small, single-responsibility scripts that are sourced by a
`main.sh` entry point and tied together by a `menu.sh`.

```
AWS-CLI-Manager/
├── EC2/
│   ├── main.sh             # Entry point: sources modules, runs pre-flight checks, starts menu
│   ├── menu.sh             # Interactive menu and command dispatch
│   ├── config.sh           # Shared config (default region) and helpers
│   ├── install.sh          # AWS CLI detection / installation (Linux, macOS)
│   ├── auth.sh             # Credential verification (aws sts get-caller-identity)
│   ├── regions.sh          # Region selection
│   ├── keypairs.sh         # Key pair creation and listing
│   ├── create_instance.sh  # Instance creation workflow (type, distro, AMI, SG)
│   └── instances.sh        # List / details / start / stop / reboot / terminate / SSH
└── README.md
```

### Module conventions

Each service module follows the same pattern, which makes the codebase
predictable and keeps future modules consistent:

| File | Responsibility |
|------|----------------|
| `main.sh` | Sources the other scripts, runs pre-flight checks, launches the menu. |
| `menu.sh` | Renders the interactive menu and maps user input to functions. |
| `config.sh` | Shared variables and small helpers (`error_exit`, `pause`). |
| `*.sh` (feature files) | One concern per file (key pairs, instances, etc.). |

### Execution flow (EC2)

`main.sh` runs three pre-flight steps before showing the menu:

1. `check_aws_cli` — verify the AWS CLI is installed (offer to install it if not).
2. `check_credentials` — verify credentials via `aws sts get-caller-identity`
   (run `aws configure` if needed).
3. `select_region` — choose the working region.

It then enters `main_menu`, which loops until you exit.

### Adding a new module

New services follow the existing layout: create a new top-level directory
(e.g. `S3/`) containing its own `main.sh`, `menu.sh`, and feature scripts. This
keeps modules independent and is why the planned **Unified AWS Manager** (v1.0)
can later compose them into a single multi-service menu without restructuring
existing code.

---

## Features

### EC2 (current)

**Setup & environment**
- AWS CLI detection and installation (Linux via `apt`, macOS via `installer`)
- AWS credential verification and configuration (`aws sts get-caller-identity`,
  `aws configure`)
- Region selection (`ap-south-1`, `us-east-1`, `us-west-2`, `eu-west-1`)

**Instance lifecycle**
- Create an EC2 instance (guided: name, type, distribution, key pair)
- List instances (ID, state, type, public IP)
- View instance details (name, state, type, public/private IP, launch time, AMI)
- Start an instance
- Stop an instance
- Reboot an instance (with confirmation)
- Terminate an instance (requires typing `DELETE` to confirm)
- SSH into an instance (prompts for SSH user and PEM key path)

**Key pairs**
- Create a key pair (saved locally as `<name>.pem`, `chmod 400`)
- List key pairs

**Instance creation details**
- Instance types: `t2.micro`, `t3.micro`
- Multi-distribution support with automatic latest-AMI resolution:
  - **Amazon Linux 2023** — via SSM public parameter (`ec2-user`)
  - **Ubuntu 24.04 LTS** — via Canonical-owned AMI lookup (`ubuntu`)
  - **Ubuntu 22.04 LTS** — via Canonical-owned AMI lookup (`ubuntu`)
  - **Debian 12** — via Debian-owned AMI lookup (`admin`)
- Automatically uses the account's **default VPC**
- Creates (or reuses) a security group named `ec2-manager-sg` that opens
  **port 22 (SSH) to `0.0.0.0/0`** — see the [Security](#security) notice
- Waits for the instance to reach the `running` state and reports its public IP

> **Note:** Distribution AMIs are resolved at creation time from AWS, so the
> latest available image for each distribution is used automatically.

---

## Requirements

- **Bash** (the scripts use `#!/bin/bash`)
- **AWS CLI v2** — the tool can install it for you on Linux/macOS if missing
- **An AWS account** with credentials (access key / secret, or an otherwise
  configured profile)
- **`ssh`** on your machine (for the SSH-into-instance feature)
- Standard utilities used during AWS CLI install on Linux: `curl`, `unzip`

> Using AWS will incur charges on your account according to AWS pricing. You are
> responsible for any resources this tool creates.

---

## Installation

Clone the repository:

```bash
[git clone <repository-url>](https://github.com/AbhishekMauryaGEEK/AWS-CLI-Manager)
cd AWS-CLI-Manager
```

Make the EC2 scripts executable:

```bash
chmod +x EC2/*.sh
```

The scripts source each other using relative paths, so run the tool **from
inside the module directory**:

```bash
cd EC2
./main.sh
```

On first run, the tool will:

1. Check for the AWS CLI and offer to install it if it is missing.
2. Verify your AWS credentials and run `aws configure` if needed.
3. Ask you to select a region.

---

## Usage

Launch the EC2 manager:

```bash
cd EC2
./main.sh
```

You will be presented with the interactive menu:

```
==============================
   AWS EC2 MANAGER
==============================

EC2 MANAGEMENT
------------------------------------------
1. Create Instance
2. List Instances
3. Instance Details
4. Start Instance
5. Stop Instance
6. Reboot Instance
7. Terminate Instance

KEY PAIRS
------------------------------------------
8. Create Key Pair
9. List Key Pairs

SETTINGS
------------------------------------------
10. Change Region
11. SSH Into Instance

0. Exit
```

### Example: create your first instance

1. Select **8** to create a key pair (e.g. `my-key`). It is saved locally as
   `my-key.pem` with `400` permissions.
2. Select **1** to create an instance:
   - Enter an instance name.
   - Choose an instance type (`t2.micro` / `t3.micro`).
   - Choose the key pair you just created.
   - Choose a distribution (Amazon Linux 2023, Ubuntu 24.04/22.04, Debian 12).
   - Review the summary and confirm to launch.
3. Select **2** to list instances and copy the new instance ID.
4. Select **11** to SSH in — provide the SSH user and the path to your `.pem`
   file.

### Example: stop or terminate an instance

- Select **5** (Stop) and enter the instance ID to stop a running instance.
- Select **7** (Terminate), enter the instance ID, and type `DELETE` to confirm
  permanent deletion.

> Each menu action is a thin wrapper around an `aws ec2 ...` command. If you
> prefer, you can read the corresponding script to see exactly what is run.

---

## Configuration

- **Default region** — defined in `EC2/config.sh` as `AWS_REGION`
  (defaults to `ap-south-1`). You can change the active region at runtime from
  the menu (**option 10**), which also runs `aws configure set region`.
- **Credentials** — managed by the AWS CLI itself (`aws configure`). This tool
  does not store credentials; it relies on your standard AWS CLI configuration.
- **Security group** — instance creation uses a security group named
  `ec2-manager-sg`, created automatically in the default VPC if it does not
  already exist.

---

## Screenshots

<!-- Add screenshots or terminal recordings here as the project matures. -->

| View | Preview |
|------|---------|
| Main menu | _placeholder — add screenshot_ |
| Create instance flow | _placeholder — add screenshot_ |
| Instance list / details | _placeholder — add screenshot_ |

> _Tip: terminal recordings (e.g. asciinema) work well for menu-driven tools._

---

## Roadmap

The roadmap is organized so that each new AWS service is added as an independent
module under its own directory, following the existing structure.

### v0.2 — S3 module
- Bucket management
- File upload / download

### v0.3 — IAM module
- User management
- Policy management

### v0.4 — VPC module
- VPC management
- Subnet management
- Security group management

### v1.0 — Unified AWS Manager
- Multi-service menu system
- Cross-service workflows

> Roadmap items are aspirational and may change. Only features listed under
> [Features](#features) are currently implemented.

---

## Contributing

Contributions are welcome. Because the project is organized by service module,
contributions tend to fall into two categories: improving an existing module, or
adding a new one.

### Guidelines

1. **Fork and branch** — create a feature branch for your change.
2. **Follow the module layout** — keep one concern per file and source feature
   scripts from `main.sh`. New services go in their own top-level directory with
   their own `main.sh` and `menu.sh`.
3. **Match the existing style** — POSIX-friendly Bash, clear `[OK]` / `[INFO]` /
   `[ERROR]` status messages, and confirmation prompts for destructive actions.
4. **Keep wrappers transparent** — each menu action should map to a clear,
   inspectable `aws` command.
5. **Test against a real AWS account** in a non-production region before opening
   a pull request, and note what you tested.
6. **Do not commit secrets** — see the [Security](#security) section. Private
   keys, `.env` files, and local AWS config are gitignored and must stay that
   way.

### Opening a pull request

- Describe the change and the module it affects.
- Include the commands you ran to verify it.
- Keep pull requests focused and reasonably small.

---

## Security

Please read this section before using the tool against any account you care
about.

- **SSH is open to the world.** When creating an instance, the tool creates (or
  reuses) a security group named `ec2-manager-sg` that allows inbound TCP port
  22 from `0.0.0.0/0`. This is convenient for getting started but is **not**
  appropriate for production. Restrict the ingress CIDR to trusted IP ranges for
  any real use.
- **Private keys are written to disk.** Creating a key pair saves a `.pem` file
  in the current directory with `chmod 400`. Keep these files safe; anyone with
  the `.pem` can access the corresponding instances. `*.pem` and `*.key` are
  listed in `.gitignore` — never commit them.
- **Credentials are handled by the AWS CLI.** This tool does not store or
  transmit your credentials; it relies on your local AWS CLI configuration.
  `.env` and `.aws/` are gitignored.
- **Actions cost money and can be destructive.** Creating, running, and
  terminating instances affects real AWS resources and billing. Destructive
  actions (terminate, reboot) require explicit confirmation, but you remain
  responsible for what you launch.
- **Review before you run.** Every action is a wrapper around an `aws` command.
  If in doubt, read the relevant script first.

If you discover a security issue, please open an issue (or contact the
maintainers privately if the project later defines a disclosure process) rather
than including sensitive details in a public report.

---

## License

License: **TBD**.

<!--
Choose and add a license (e.g. MIT, Apache-2.0) and a LICENSE file, then
update this section and the License badge above accordingly.
-->
