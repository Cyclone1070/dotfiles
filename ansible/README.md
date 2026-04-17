# Ansible Homelab Setup

This directory contains playbooks and inventory for managing the homelab.

## Prerequisites

Before running the bootstrap, ensure the following are configured:

### 1. Tailscale OAuth Credentials

Create `ansible/vars/secrets.yml` with your Tailscale OAuth Client ID and Secret:

```yaml
tailscale_client_id: "YOUR_CLIENT_ID"
tailscale_client_secret: "tskey-client-..."
```

**OAuth Scopes Required:**

- `devices` (Read & Write)
- `auth_keys` (Write)

### 2. Local Machine Setup

- Your local machine **must be connected to Tailscale** (if you are on mac you must use the app, not the brew version).
- Ensure `ansible` is installed locally.

## Initial Bootstrap (Fresh Machine)

### Step 1: Run the Bootstrap Command

Execute the following command from your Mac to set up a new machine:

```bash
ansible-playbook -i '<remote_ip>,' bootstrap.yml -e "target_hostname=<target_hostname>" -u <remote_user> --ask-pass -K
```

Then enter ssh and sudo passwords when prompted.

#### Arguments

- **`<remote_ip>`**: The IPv4 address of your new machine (e.g., `192.168.1.50`).
- **`<target_hostname>`**: The final name you want for your machine (e.g., `elitedesk`).
- **`-u <remote_user>`**: (Optional) The username on the fresh machine (e.g., `-u fedora`). Only required if the username is different from the local username.

#### What this command does

- **Hostname Configuration:** Changes the OS name to `<target_hostname>`.
- **Access Hardening:** Automatically detects or generates an SSH key on your Mac and deploys it for passwordless login.
- **Tailscale Integration:** Installs and authorizes Tailscale automagically.
- **Automatic Inventory:** On success, it appends `<target_hostname> ansible_host=<target_hostname>` to your `inventory.ini`.

---

## Day-to-Day Management

After bootstrapping, Tailscale will handle the networking. You can run your regular playbooks using your assigned hostname:

```bash
ansible-playbook playbook_server.yml
```

## Security Note

The `vars/secrets.yml` contains Tailscale OAuth credentials. This file is currently ignored by Git. Check your root `.gitignore` to verify it's active.
