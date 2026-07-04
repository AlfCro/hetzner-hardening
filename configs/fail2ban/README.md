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

## Caddy Auth-Failure Jail

Use `caddy-auth.conf` and `caddy-auth.local.example` for Caddy JSON access logs
where protected endpoints return repeated `401` or `403` responses. The tested
pattern expects Caddy's current JSON field names:

```json
{"ts":1783162589.2277133,"request":{"remote_ip":"65.21.3.33",...},"status":401,...}
```

The filter uses `datepattern = "ts":{EPOCH}` because Caddy's timestamp is
inside the JSON object rather than at the beginning of the line. If your Caddy
version logs `remote_addr` instead of `remote_ip`, change the filter and retest
with `fail2ban-regex` before enabling the jail.

The example policy is gentler than SSH: 10 failures in 10 minutes earns a
1-hour ban. This avoids punishing normal browser retries while still throttling
credential stuffing through app login surfaces.
