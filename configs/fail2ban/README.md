# Fail2ban Templates

Reusable jail/filter snippets for public services beyond SSH. Treat these as
starting points: install them into `/etc/fail2ban/`, test with
`fail2ban-regex` against the target server's real logs, then reload fail2ban.

Every public listener should get a matching throttle in the same change that
opens it:

- use `ufw limit` for credential-bearing TCP listeners;
- use fail2ban when the service logs source IPs or enough connection metadata;
- verify the jail's effective `maxretry`, `findtime`, `bantime`, `ignoreip`,
  and `logpath` with `fail2ban-client get ...`.

## Mosquitto Auth / Connection-Rate Jail

Mosquitto 2.x often logs the source IP on `New connection from ...` and then
logs `not authorised` on the next line without the IP. In that case, do not
pretend the auth failure line identifies the source. Use the connection-rate
filter in this directory with a higher retry budget.

The tested cronmalm pattern is:

- filter: `mosquitto-auth.conf`
- jail: `mosquitto.local.example`
- port: `8883`
- maxretry/findtime: `20` connections in `120` seconds
- bantime: `86400`

The filter was tested against logs like:

```text
1783162405: New connection from 65.21.3.33:50312 on port 8883.
1783162405: Client auto-... disconnected, not authorised.
```

Fail2ban parses the leading epoch timestamp separately, so the regex matches
the post-date line body beginning with `: New connection ...`.
