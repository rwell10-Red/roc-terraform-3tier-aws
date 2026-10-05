# Linux / WSL Setup & Reference Guide

A learning + reference doc for moving the Terraform workflow onto Linux via WSL
(Windows Subsystem for Linux) on this Windows 11 machine.

---

## 1. Why Linux / WSL for this project

This is a 3-tier AWS Terraform project with a GitHub Actions CI/CD pipeline.
In real-world DevOps/cloud work, tooling (AWS CLI, Terraform, Docker, kubectl)
typically runs on **Linux**, and CI/CD runners are almost always Linux. Running
the same tools locally in WSL means your dev environment mirrors where the code
actually deploys. Good practice, and good portfolio signal.

### This machine (detected)

| Property      | Value                                   |
|---------------|-----------------------------------------|
| OS            | Windows 11 Home (build 26200)           |
| Architecture  | AMD64 (x86_64, 64-bit)                   |
| Default shell | PowerShell 5.1                          |
| Git Bash      | Installed (`C:\Program Files\Git\bin`)  |
| WSL           | NOT installed (install below)           |

---

## 2. Install WSL + Ubuntu

Open **PowerShell as Administrator** (right-click > Run as administrator) and run:

```powershell
wsl --install
```

This one command:
- Enables the WSL and Virtual Machine Platform Windows features
- Installs the WSL 2 kernel
- Downloads and installs **Ubuntu** (the default distro)

Then **reboot** when prompted. After reboot, Ubuntu launches and asks you to
create a **Linux username and password** (separate from your Windows login —
pick something memorable; the password is used for `sudo`).

### Verify

Back in PowerShell:

```powershell
wsl -l -v
```

Expected: Ubuntu listed with `VERSION 2`.

### Optional — other distros

```powershell
wsl --list --online        # see available distros
wsl --install -d Debian    # example: install Debian instead
```

---

## 3. Golden rule: where to store project files

**Official Microsoft guidance:** store files in the filesystem of the OS you
work from. If you work from the Linux command line, keep files **in the Linux
filesystem** (`/home/<user>/...`), NOT under `/mnt/c/...`.

> Microsoft, *Working across file systems*: they recommend against working
> across operating systems with your files unless you have a specific reason;
> for fastest performance, store files in the WSL (Linux) file system when
> working from a Linux command line, and in the Windows file system when working
> from a Windows command line (PowerShell/Command Prompt).

- Fast (do this):  `/home/<user>/roc-terraform-3tier-aws`
- Slow (avoid):    `/mnt/c/Users/arock/.../AWS_TerraForm`

**Why:** every file operation under `/mnt/c` crosses the Windows<->Linux
boundary, which adds real overhead — worst for workloads with many small file
operations. Native Linux filesystem writes are several times faster, and
metadata operations dramatically faster.

**The Linux-side technical reason:** when WSL 2 accesses a mounted Windows drive
(`/mnt/c`), it uses the **9P network filesystem protocol**, which is **not
POSIX-compliant**. That non-compliance is what causes the slowdown and can cause
errors or unexpected behavior in some Linux applications. The Linux home
directory, by contrast, lives on an ext4 VolFS filesystem that fully supports
Linux permissions, symlinks, FIFOs, sockets, and device files. (See Linux-side
sources in Section 8.)

**Safety rule:** NEVER edit files inside the Linux filesystem using Windows apps
or tools — it can corrupt them. The only safe cross-access direction is Linux
reaching Windows files via `/mnt/c`. To edit Linux files with a GUI editor, use
**VS Code WSL remote mode** (the sanctioned way).

### Getting the project onto Linux — Option A vs Option B

There are two ways to get this project into the Linux filesystem. Both end with
the files living under `/home/<user>/...` (the fast, recommended location).

**Option A — Clone fresh from GitHub (RECOMMENDED).**
Because the project is already a git repo on GitHub, clone it directly into the
Linux home directory. Cleanest result, nothing crosses the slow boundary, and
you get a pristine checkout.

```bash
cd ~
git clone https://github.com/rwell10-Red/roc-terraform-3tier-aws.git
cd roc-terraform-3tier-aws
```

Pros: fastest, cleanest, no boundary crossing, matches real-world practice.
Cons: any local-only uncommitted changes on the Windows side won't come along
(commit + push them first if you have any).

**Option B — Copy the existing Windows folder across.**
Reach the Windows files via `/mnt/c` and copy them into the Linux home dir. Use
this only if you have local changes that aren't committed to GitHub yet.

```bash
cp -r /mnt/c/Users/arock/Home/Rockwell/Rockwell/CICD/AWS_TerraForm ~/roc-terraform-3tier-aws
cd ~/roc-terraform-3tier-aws
```

Pros: brings everything exactly as-is, including uncommitted/untracked files.
Cons: the *source* is on the slow `/mnt/c` boundary so the copy is slower; may
carry across Windows line endings or stray local files (`.terraform/`, state).

**What Microsoft officially recommends:** store the files on the Linux
filesystem when working from Linux — which both options achieve. Microsoft also
advises **against** working across filesystems routinely, which is exactly why
Option A (a clean clone that never depends on `/mnt/c`) is the preferred path,
and Option B is the fallback for the specific case of carrying over uncommitted
work.

---

## 4. Path forward (do these in order)

### Step 0 — Install WSL (Section 2), reboot, create Linux user

### Step 1 — Open Ubuntu and update packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y unzip curl git
```

### Step 2 — Get the repo into the Linux filesystem

Use **Option A (clone fresh)** unless you have uncommitted local changes, in
which case use **Option B (copy across)**. Both are described in detail in
Section 3 ("Getting the project onto Linux — Option A vs Option B"). Quick form:

```bash
# Option A (recommended)
cd ~
git clone https://github.com/rwell10-Red/roc-terraform-3tier-aws.git
cd roc-terraform-3tier-aws
```

```bash
# Option B (only if carrying over uncommitted work)
cp -r /mnt/c/Users/arock/Home/Rockwell/Rockwell/CICD/AWS_TerraForm ~/roc-terraform-3tier-aws
cd ~/roc-terraform-3tier-aws
```

### Step 3 — Install the AWS CLI (Linux x86_64)

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version          # expect aws-cli/2.x
rm -rf awscliv2.zip aws
```

### Step 4 — Install Terraform (HashiCorp apt repo)

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install -y terraform
terraform -version
```

### Step 5 — Configure AWS IAM Identity Center (SSO)

Prereq (one-time, in AWS Console): enable IAM Identity Center, create a user,
create an `AdministratorAccess` permission set, assign user to the account, and
copy the **AWS access portal URL** (looks like
`https://d-xxxxxxxxxx.awsapps.com/start`).

```bash
aws configure sso --profile personal
```

Prompts:
- **SSO start URL** -> the portal URL
- **SSO Region** -> region where Identity Center is enabled (e.g. us-east-1)
- Browser opens -> sign in and approve
- Select account + role
- **CLI default region** -> e.g. us-east-1 (keep consistent everywhere)
- **CLI default output** -> json
- **profile name** -> personal

Verify:

```bash
aws sts get-caller-identity --profile personal
```

Re-login when the SSO token expires:

```bash
aws sso login --profile personal
```

### Step 6 — Tell Terraform which profile to use

```bash
export AWS_PROFILE=personal
# (add to ~/.bashrc to make it persistent)
```

### Step 7 — Bootstrap remote state, then deploy

```bash
cd bootstrap
terraform init
terraform apply            # note the bucket_name output
cd ..

# put the bucket name into main.tf backend, OR pass at init:
terraform init -backend-config="bucket=<BUCKET_NAME>" \
               -backend-config="key=dev/terraform.tfstate"

terraform plan  -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

> NOTE: `terraform apply` creates real, billable AWS resources (RDS, ALB, NAT,
> EC2). Run `terraform destroy -var-file="environments/dev.tfvars"` to tear down.

---

## 6. VS Code / Kiro with WSL (editing Linux files safely)

Install the **WSL** extension in VS Code, then from the Ubuntu shell inside your
project run:

```bash
code .
```

This opens the editor connected into the Linux filesystem — the safe, supported
way to edit Linux files with a Windows GUI editor.

> Tooling hand-off note: once AWS CLI + Terraform + the repo live inside WSL,
> commands must be run from the Ubuntu shell by you. Automated assistants that
> execute in Windows PowerShell cannot (and should not) reach into the Linux
> filesystem to run them.

---

## 7. Handy WSL commands (reference)

| Command                              | What it does                             |
|--------------------------------------|------------------------------------------|
| `wsl -l -v`                          | List installed distros + WSL version     |
| `wsl --install`                      | Install WSL + default Ubuntu             |
| `wsl --install -d <distro>`          | Install a specific distro                |
| `wsl --list --online`                | Show installable distros                 |
| `wsl --set-default <distro>`         | Set default distro                       |
| `wsl --shutdown`                     | Stop all WSL instances                   |
| `wsl --update`                       | Update the WSL kernel                    |
| `wsl --unregister <distro>`          | Remove a distro (deletes its files!)     |
| `explorer.exe .`                     | Open current Linux dir in Windows Explorer |
| `code .`                             | Open current dir in VS Code (WSL remote) |

Access paths:
- Windows C: drive from inside Linux -> `/mnt/c/...`
- Linux files from Windows Explorer  -> `\\wsl$\Ubuntu\home\<user>\...`

---

## 8. Sources / further reading & cross-references

### Microsoft (Windows / WSL side)

- Working across file systems (Microsoft Learn) — the primary "where to store
  files + performance" guidance:
  https://learn.microsoft.com/en-us/windows/wsl/filesystems
- Same doc, source on GitHub (MicrosoftDocs/WSL):
  https://github.com/MicrosoftDocs/wsl/blob/main/WSL/filesystems.md
- Do NOT change Linux files using Windows apps and tools (WSL team blog) — the
  corruption safety rule:
  https://devblogs.microsoft.com/commandline/do-not-change-linux-files-using-windows-apps-and-tools/
- How to manage WSL disk space (Microsoft Learn):
  https://learn.microsoft.com/en-us/windows/wsl/disk-space

### Linux / Ubuntu side (cross-references to the Microsoft guidance)

These independent, Linux-side sources state the same recommendation, which is
useful for confirming it isn't just a Windows-centric opinion:

- Ubuntu on WSL documentation (Canonical — makers of Ubuntu):
  https://documentation.ubuntu.com/wsl/latest/tutorials/develop-with-ubuntu-wsl/
- Ubuntu on WSL product page (Canonical):
  https://ubuntu.com/wsl
- Docker — WSL 2 best practices (independent vendor, same guidance: keep files
  on the Linux filesystem, avoid bind-mounting `/mnt/c`):
  https://docs.docker.com/desktop/features/wsl/best-practices/
- The 9P / non-POSIX technical reason `/mnt/c` is slow (community, Super User):
  https://superuser.com/questions/1727140/wsl-2-0-ubuntu-relocating-home-directory
- VolFS / ext4 details of the Linux home filesystem (Ask Ubuntu):
  https://askubuntu.com/questions/759880/where-is-the-ubuntu-file-system-root-directory-in-windows-subsystem-for-linux-an

### AWS & HashiCorp (tooling)

- Install the AWS CLI (AWS docs):
  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Configure SSO for the AWS CLI (AWS docs):
  https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html
- Install Terraform (HashiCorp docs):
  https://developer.hashicorp.com/terraform/install

> Note on sources: the official Microsoft Learn and Ubuntu/Docker docs are the
> authoritative guidance. Performance magnitudes (e.g. multiple-times-faster
> writes on the Linux filesystem) and the 9P-protocol explanation were
> cross-referenced from community testing and Q&A (howtogeek, dev.to, Super
> User, Ask Ubuntu) and align with the official guidance. Content was rephrased
> for compliance with licensing restrictions.
