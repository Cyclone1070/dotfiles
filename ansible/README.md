# Ansible Homelab Setup

This directory contains playbooks and inventory for managing the homelab.

## Initial Bootstrap (Fresh Machine)

When you have a new machine (e.g., Fedora server) and you want to set it up for the first time:

### Step 1: Run the Bootstrap Command

Execute the following command from your Mac:

```bash
ansible-playbook -i '<remote_ip>,' bootstrap.yml -e "target_hostname=<target_hostname>" -u <remote_user> --ask-pass
```

### Arguments

- **`<remote_ip>`**: The temporary IPv4 address of your new machine (e.g., `192.168.1.50`).
- **`<target_hostname>`**: The final name you want for your machine (e.g., `elitedesk`).
- **`-u <remote_user>`**: (Optional) The temporary username on the fresh machine (e.g., `-u fedora`).

### What this command does

- **Sets the Hostname:** Changes the OS name to `<target_hostname>`.
- **Secures Access:** Deploys your `~/.ssh/id_rsa.pub` so you no longer need passwords.
- **Joins Tailscale:** Installs and authorizes Tailscale automagically.
- **Self-Updates:** On success, it automatically appends `<target_hostname> ansible_host=<target_hostname>` to your `inventory.ini`.

---

## Day-to-Day Management

After bootstrapping, Tailscale will handle the networking. You can run your regular playbooks using your assigned hostname:

```bash
ansible-playbook playbook_server.yml
```

## Security Note

The `vars/secrets.yml` contains Tailscale OAuth credentials. You should have already added this to your root `.gitignore`. Check `.gitignore` to be sure.
