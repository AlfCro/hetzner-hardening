# Tailscale & Expo Development

With Tailscale on both your phone and VPS, your phone can reach dev servers directly over the encrypted mesh network -- no public ports needed.

```bash
# On VPS
npx expo start --host <tailscale-ip>

# Phone connects at
http://<tailscale-ip>:8081
```

This replaces the need for a Hetzner private network for dev purposes.

## VNC If Needed (Tunnel Only)

```bash
ssh -L 5901:localhost:5901 deploy@<tailscale-ip> -p 41122
```

Never expose VNC ports publicly, even if the process is running.
