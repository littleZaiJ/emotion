# clarity

A new Flutter project.

## Getting Started

### Run on Web (localhost:3000)

This repo is a Flutter app (not a Node server).

To serve it locally on port 3000, use an explicit hostname to avoid IPv4/IPv6 `localhost` resolution issues:

```bash
cd clarity
flutter run -d web-server --web-port 3000 --web-hostname 127.0.0.1
```

Then open `http://127.0.0.1:3000/`.

Tip: there is a helper script you can run instead:

```bash
cd clarity
bash scripts/run_web.sh
```

#### Troubleshooting “can’t access”

- If you *must* use `http://localhost:3000/` and it fails, your machine may be preferring IPv6 (`::1`) while the server is listening on IPv4 (or vice versa). Fix by using an explicit address:
  - IPv4: `--web-hostname 127.0.0.1` + open `http://127.0.0.1:3000/`
  - IPv6: `--web-hostname ::1` + open `http://[::1]:3000/`
- If you need to access from another device (same LAN) or you’re running inside a container/remote dev env, bind all interfaces:
  - `flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0`
  - Or: `HOST=0.0.0.0 PORT=3000 bash scripts/run_web.sh`
  - Open `http://<your-machine-lan-ip>:3000/` (and ensure port 3000 is forwarded/open).
- Check whether the port is already in use:
  - macOS: `lsof -nP -iTCP:3000 -sTCP:LISTEN`
  - Linux: `ss -ltnp | rg ':3000'`

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
