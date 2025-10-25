# Ansible Compliance & Remediation Playbooks

This repository contains Ansible playbooks and support files for running system compliance checks and automated remediation.

This document explains how to run the playbooks in this repo (except `pre-task.sh`, per request). It assumes you're using zsh on macOS (as seen in the workspace context).

## Contents

- `compliance_check.yml` - Playbook that reads `controls.csv`, executes checks, and writes a JSON compliance report.
- `remediation.yml` - Playbook that reads a saved compliance report and attempts to remediate items marked `remediable: true`.
- `controls.csv` - CSV file listing controls and how to check and remediate them.
- `inventory.ini` - Ansible inventory. Adjust as needed.

## Prerequisites

- Ansible installed on your control node (recommended: ansible-core 2.12+ or latest stable). To check:

```zsh
ansible --version
```

- Python 3 on control node (zsh is the user shell in these examples).
- SSH access to target hosts with a key or passwordless sudo for the account used by Ansible.
- Ensure `controls.csv` is present in the repo root. The compliance playbook copies this to `/tmp/controls.csv` on target hosts.

Notes about remote Python interpreter:
- If the remote host uses a non-default Python path, set `ansible_python_interpreter` in `inventory.ini` or host_vars, e.g.:

```
[awsServer]
ec2-54-254-157-69.ap-southeast-1.compute.amazonaws.com ansible_user=ec2-user ansible_python_interpreter=/usr/bin/python3.8
```

## Running the compliance checks

1. Ensure your inventory is correct in `inventory.ini` and SSH connectivity works:

```zsh
ansible -i inventory.ini -m ping all -u <user>
```

2. Run the compliance check playbook (control node / workspace root):

```zsh
# run with default inventory
ansible-playbook -i inventory.ini compliance_check.yml

# run with verbose output for debugging
ansible-playbook -i inventory.ini compliance_check.yml -vvv
```

What it does:
- Copies `controls.csv` to `/tmp/controls.csv` on the target host.
- Runs the checks defined in `controls.csv` (via `compliance_check_block.yml`) and accumulates results in `compliance_report`.
- Writes a JSON report to `/tmp/compliance_report_<hostname>.json` (configurable via variable `cloudera_compliance_report`).
- Prints a sorted compliance summary grouped by status.

Notes:
- The playbook expects results to include `status` and (for non-compliant items) `actual_result` when present.

## Running remediation

After you have a compliance report (created by the `compliance_check.yml` run), run the remediation playbook to attempt automatic fixes for remediable items.

```zsh
ansible-playbook -i inventory.ini remediation.yml

# verbose
ansible-playbook -i inventory.ini remediation.yml -vvv
```

What it does:
- Loads `/tmp/compliance_report_<hostname>.json` (the playbook reads the file for the host it targets). Ensure the file exists on the controller or has been copied to the remote host as the play expects.
- Filters items with `status != COMPLIANT` and `remediable == true`.
- Attempts remediation commands (the playbook registers and displays results). The playbook now ignores errors for remediation commands so it can continue to attempt further remediations.
- Verifies remediation by running configured check commands and determines success by matching stdout to `expected_result` (or rc==0 when no expected result is configured).

Important reboot behavior:
- If a remediation issues `reboot`, Ansible's SSH connection will drop and the host will be marked `unreachable` until it comes back up. Use the `reboot` module or wrap reboot operations with a `rescue` and wait/reconnect strategy if you want the playbook to resume automatically.

## Common troubleshooting and tips

- Error: `SyntaxError: future feature annotations is not defined` or module failures referencing `ansible.module_utils.basic`:
  - This usually indicates the remote Python is too old for the Ansible module code. Install/point Ansible to Python 3.8+ on remote and set `ansible_python_interpreter` in inventory.

- Error: `TypeError: unsupported operand type(s) for |: '_Environ' and 'dict'` from `dnf` module:
  - Some combinations of Ansible version and remote Python cause module respawn logic to fail when Ansible tries to probe interpreters. Workarounds:
    - Use `yum` (or `raw` fallback) instead of `dnf` in tasks.
    - Upgrade Ansible to a newer version on the control node.
    - Clean remote `/home/<user>/.ansible/tmp` before re-running.

- Host becomes unreachable after `reboot` remediation:
  - This is expected. Use the `reboot` module with `reboot_timeout` and `test_command` so Ansible waits for host availability.

- Force push / git errors:
  - Make an initial commit locally and push without `-f`. If branch is protected on remote, push to a new branch and create a merge request.

## Variables you can tune

- `controls_file` - path to CSV file (default `controls.csv`).
- `csv_delimiter` - CSV delimiter, default `,`.
- `cloudera_compliance_report` - output JSON path on target host (or controller if used that way).
- `items_to_remediate` and `valid_controls` - internal variables used by the remediation playbook to determine which items to attempt.

## Example: Run only a single task or tag

If you want to run a single included task file for testing, you can use `--start-at-task` with the exact task name printed by the playbook output. Or run with tags if implemented.

```zsh
# Run starting at a specific task name
ansible-playbook -i inventory.ini remediation.yml --start-at-task "Display Items to Remediate"
```

## Verification / Outputs

- Compliance JSON files are written to `/tmp/compliance_report_<inventory_hostname>.json` by default. Inspect them with `jq` or `python -m json.tool`.

```zsh
ansible -i inventory.ini -m shell -a 'cat /tmp/compliance_report_$(hostname).json' myAppServer
```

## Security & best practices

- Do not store sensitive credentials directly in `controls.csv` or playbooks. Use Ansible Vault for secrets.
- Review remediation commands carefully — some commands (like `reboot`, package removals, or system config changes) may have service impact.

## If something is unclear

Open an issue or describe the failing task output. Include the task debug output and the relevant parts of `controls.csv` for the failing control.

---
End of documentation.
<<<<<<< HEAD
# v3



## Getting started

To make it easy for you to get started with GitLab, here's a list of recommended next steps.

Already a pro? Just edit this README.md and make it your own. Want to make it easy? [Use the template at the bottom](#editing-this-readme)!

## Add your files

- [ ] [Create](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#create-a-file) or [upload](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#upload-a-file) files
- [ ] [Add files using the command line](https://docs.gitlab.com/topics/git/add_files/#add-files-to-a-git-repository) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin https://gitlab.com/arunshan04-group/CDP_Pretask.git
git branch -M main
git push -uf origin main
```

## Integrate with your tools

- [ ] [Set up project integrations](https://gitlab.com/arunshan04-group/CDP_Pretask/-/settings/integrations)

## Collaborate with your team

- [ ] [Invite team members and collaborators](https://docs.gitlab.com/ee/user/project/members/)
- [ ] [Create a new merge request](https://docs.gitlab.com/ee/user/project/merge_requests/creating_merge_requests.html)
- [ ] [Automatically close issues from merge requests](https://docs.gitlab.com/ee/user/project/issues/managing_issues.html#closing-issues-automatically)
- [ ] [Enable merge request approvals](https://docs.gitlab.com/ee/user/project/merge_requests/approvals/)
- [ ] [Set auto-merge](https://docs.gitlab.com/user/project/merge_requests/auto_merge/)

## Test and Deploy

Use the built-in continuous integration in GitLab.

- [ ] [Get started with GitLab CI/CD](https://docs.gitlab.com/ee/ci/quick_start/)
- [ ] [Analyze your code for known vulnerabilities with Static Application Security Testing (SAST)](https://docs.gitlab.com/ee/user/application_security/sast/)
- [ ] [Deploy to Kubernetes, Amazon EC2, or Amazon ECS using Auto Deploy](https://docs.gitlab.com/ee/topics/autodevops/requirements.html)
- [ ] [Use pull-based deployments for improved Kubernetes management](https://docs.gitlab.com/ee/user/clusters/agent/)
- [ ] [Set up protected environments](https://docs.gitlab.com/ee/ci/environments/protected_environments.html)

***

# Editing this README

When you're ready to make this README your own, just edit this file and use the handy template below (or feel free to structure it however you want - this is just a starting point!). Thanks to [makeareadme.com](https://www.makeareadme.com/) for this template.

## Suggestions for a good README

Every project is different, so consider which of these sections apply to yours. The sections used in the template are suggestions for most open source projects. Also keep in mind that while a README can be too long and detailed, too long is better than too short. If you think your README is too long, consider utilizing another form of documentation rather than cutting out information.

## Name
Choose a self-explaining name for your project.

## Description
Let people know what your project can do specifically. Provide context and add a link to any reference visitors might be unfamiliar with. A list of Features or a Background subsection can also be added here. If there are alternatives to your project, this is a good place to list differentiating factors.

## Badges
On some READMEs, you may see small images that convey metadata, such as whether or not all the tests are passing for the project. You can use Shields to add some to your README. Many services also have instructions for adding a badge.

## Visuals
Depending on what you are making, it can be a good idea to include screenshots or even a video (you'll frequently see GIFs rather than actual videos). Tools like ttygif can help, but check out Asciinema for a more sophisticated method.

## Installation
Within a particular ecosystem, there may be a common way of installing things, such as using Yarn, NuGet, or Homebrew. However, consider the possibility that whoever is reading your README is a novice and would like more guidance. Listing specific steps helps remove ambiguity and gets people to using your project as quickly as possible. If it only runs in a specific context like a particular programming language version or operating system or has dependencies that have to be installed manually, also add a Requirements subsection.

## Usage
Use examples liberally, and show the expected output if you can. It's helpful to have inline the smallest example of usage that you can demonstrate, while providing links to more sophisticated examples if they are too long to reasonably include in the README.

## Support
Tell people where they can go to for help. It can be any combination of an issue tracker, a chat room, an email address, etc.

## Roadmap
If you have ideas for releases in the future, it is a good idea to list them in the README.

## Contributing
State if you are open to contributions and what your requirements are for accepting them.

For people who want to make changes to your project, it's helpful to have some documentation on how to get started. Perhaps there is a script that they should run or some environment variables that they need to set. Make these steps explicit. These instructions could also be useful to your future self.

You can also document commands to lint the code or run tests. These steps help to ensure high code quality and reduce the likelihood that the changes inadvertently break something. Having instructions for running tests is especially helpful if it requires external setup, such as starting a Selenium server for testing in a browser.

## Authors and acknowledgment
Show your appreciation to those who have contributed to the project.

## License
For open source projects, say how it is licensed.

## Project status
If you have run out of energy or time for your project, put a note at the top of the README saying that development has slowed down or stopped completely. Someone may choose to fork your project or volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.
=======
# CDP_Pretask
>>>>>>> a4ab10f (Ansible Changes)
