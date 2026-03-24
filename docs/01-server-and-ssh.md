# Server Specs & SSH Keys

## Server Specs

- **Provider:** Hetzner Cloud
- **Plan:** CX22 (cost optimized)
- **OS:** Ubuntu 24.04
- **Networking:** Public IPv4 + IPv6
- **Private network:** Skipped -- Tailscale replaces this for single-server setups
- **Volumes:** Skipped -- can add extra storage later if needed
- **Cloud config / labels / placement groups:** Skipped -- not needed for single VPS
- **Backups:** Optional but recommended (~20% extra cost for weekly automatic backups, can enable later)

---

## SSH Keys

### Generating a Key

Run on your **local machine** (not the server):

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

- Accept default location (`~/.ssh/id_ed25519`)
- **Add a passphrase** -- this is your second line of defense. If someone steals your device, they still need the passphrase to use the key

### Key Is Bound to the Device

The private key lives on the device that created it. Each device (phone, laptop, desktop) should have its own key. This way, one compromised device doesn't compromise others.

### Adding a Key From a Second Device

From the new device, generate its own key, then add it to the server:

```bash
# On new device
ssh-keygen -t ed25519

# Copy to server (if port already changed)
ssh-copy-id -p 41122 deploy@<server-ip>
```

Or manually from an existing session:

```bash
echo "ssh-ed25519 AAAA...your-new-key..." >> ~/.ssh/authorized_keys
```

This works anytime -- the `deploy` user has full sudo access, so you're never locked out of adding keys.

### Passphrase vs Password Auth

- **Passphrase on key:** Protects the key file on your device. Recommended.
- **Password auth on server:** Disabled by the hardening script. These are two different things. The post says "key-only SSH auth, no passwords" -- that means no password login to the server, not about key passphrases.

---

## SSH Client (Mobile)

- **Termius** -- recommended for phone-based SSH. Purpose-built UI for managing hosts, keys, and connections.
- **Termux** -- full Linux terminal on Android, more powerful but overkill for just running SSH commands.

---

## Connection Details

| Phase | Username | Port | Notes |
|-------|----------|------|-------|
| First connection (fresh server) | `root` | `22` | Before running any scripts |
| After script step 1 | `deploy` | `41122` | Root login disabled |

**Password:** Leave blank in your SSH client -- the key handles authentication.
