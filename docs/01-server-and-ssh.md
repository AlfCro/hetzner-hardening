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

### Generating a Key in Termius

In Termius, go to **Keychain > Keys > Generate** and create an Ed25519 key. Add a passphrase -- this is your second line of defense. If someone steals your device, they still need the passphrase to use the key.

When creating the VPS on Hetzner, paste the public key from Termius into the SSH key field so root access works on first boot.

### Key Is Bound to the Device

The private key lives on the device that created it. Each device (phone, laptop, desktop) should have its own key in Termius. This way, one compromised device doesn't compromise others.

### Adding a Key From a Second Device

Generate a new key in Termius on the second device, then add its public key to the server from an existing session:

```bash
echo "ssh-ed25519 AAAA...your-new-key..." >> ~/.ssh/authorized_keys
```

This works anytime -- the `deploy` user has full sudo access, so you're never locked out of adding keys.

### Passphrase vs Password Auth

- **Passphrase on key:** Protects the key file on your device. Recommended.
- **Password auth on server:** Disabled by the hardening script. These are two different things. "Key-only SSH auth, no passwords" means no password login to the server, not about key passphrases.

---

## SSH Client

**Termius** is used for all SSH connections (phone and desktop). Set up a host entry with the server IP, username, port, and link it to the key from your Keychain. After step 1, update the host to use `deploy` on port `41122`.

---

## Connection Details

| Phase | Username | Port | Notes |
|-------|----------|------|-------|
| First connection (fresh server) | `root` | `22` | Before running any scripts |
| After script step 1 | `deploy` | `41122` | Root login disabled |

**Password:** Leave blank in your SSH client -- the key handles authentication.
