# PrivateBin for TerraMaster TOS

TerraMaster TOS 7 App Center package that installs [PrivateBin](https://github.com/PrivateBin/PrivateBin)
— a self-hosted, zero-knowledge pastebin — as a Docker application.

- **App ID:** `privatebindocker`
- **Package version:** 2.1.1-3 (upstream base 2.1.1)
- **Container image:** `privatebin/nginx-fpm-alpine:2.1.1` (Docker Hub, used unmodified)
- **Web UI:** `http://<NAS-IP>:8177/`
- **Help / privacy policy:** [PRIVACY.md](PRIVACY.md) — also the App Center help link

## Repository layout

| Path | What it is |
|---|---|
| `tosapp.json` | Application spec: image, version, ports, volumes, health check, descriptions (en / zh-cn / zh-hk) and the metadata used by the build |
| `src/config.ini` | TOS application metadata (id, name, path, help, category, dependencies) |
| `src/docker-compose.yml` | The single service: image, non-root user, port, volumes, health check, log cap, `x-app-meta` |
| `src/entrypoint.sh` | Wrapper embedded into the compose file: starts the PHP web server, forwards `SIGTERM`/`SIGINT` |
| `src/privatebindocker.lang` | 23-language UI strings (14 required by TOS, English fallback) |
| `src/privatebindocker.svg` | Application icon |
| `scripts/build.sh` | Builds one architecture: `out/privatebindocker.tar.gz` + `.sha256` |
| `scripts/build-dual.sh` | Builds both architectures and runs the official self-test on each |
| `tools/verify.py` | Review-standards self-check run by `build.sh` |
| `test/install-and-verify.sh` | On-device install and runtime check |
| `PRIVACY.md` | Privacy policy: stored data, retention, rights, security, third parties, deletion |
| `NOTICE.md` | Licences, image digest, trademark attribution |
| `CHANGELOG.md` | Version history, one entry per review finding |

Only the files above are part of the package; the App Center archive itself
contains exactly four files (`config.ini`, `privatebindocker.lang`,
`privatebindocker.svg`, `docker-compose.yml`).

## How it works

| | |
|---|---|
| Image | `privatebin/nginx-fpm-alpine:2.1.1` (Docker Hub, unmodified) |
| Open | `http://<NAS-IP>:8177/` → container port 8080 |
| Runs as | non-root, `user: "1000:1000"` |
| Pastes | `/srv/data` → `/Volume1/DockerAppData/privatebindocker/data` |
| Configuration | `/srv/cfg` → `/Volume1/DockerAppData/privatebindocker/cfg` (empty by default; drop a `conf.php` there to change limits/retention) |
| Logs | `docker logs privatebindocker`, capped at 3 × 10 MiB |

**Why a wrapper?** The upstream image serves the app with nginx on port 80, which
a non-root container cannot bind. `src/entrypoint.sh` serves the same document
root (`/var/www`) with PHP's built-in web server on 8080, keeps the paste storage
on the mounted volume, and — because PID 1 does not get default signal handling —
runs the server as a child and forwards `SIGTERM`/`SIGINT` so `docker stop`
returns immediately instead of waiting out the grace period (review finding F3).

## Privacy

PrivateBin stores **ciphertext only**: the browser encrypts the paste with
AES-256-GCM (PBKDF2-HMAC-SHA256, 100 000 iterations), and the key is placed in the
URL fragment (`#…`), which browsers never send to the server. The app has no
accounts, no analytics, no telemetry, no CDN and makes no outbound connection by
default. Everything it writes lives in
`/Volume1/DockerAppData/privatebindocker/`.

The full policy — what is stored, where, for how long, what the server logs
contain, which optional features talk to third parties, your rights and the
deletion channel — is in [PRIVACY.md](PRIVACY.md). The App Center help link points
there.

## Notices

Upstream PrivateBin is distributed under the **Zlib licence (with
acknowledgement)**; the container image is the official Docker Hub image
`privatebin/nginx-fpm-alpine:2.1.1` (digest `sha256:9fbcc4d5…`), used unmodified.
This packaging is MIT-licensed original work by Moechz. PrivateBin and the
PrivateBin logo are trademarks of the upstream project; TerraMaster is a
trademark of TerraMaster. This package is an independent community submission and
is not affiliated with either. Details: [NOTICE.md](NOTICE.md).

## Build

```bash
scripts/build-dual.sh 2.1.1-3      # both architectures + official check
scripts/build.sh 2.1.1-3 aarch64   # one architecture only
```

`build.sh` stages the four package files, substitutes `@@VERSION@@` /
`@@PLATFORM@@`, embeds `src/entrypoint.sh` into the compose block scalar (every
`$` becomes `$$`), normalises line endings, runs `tools/verify.py` (layout, JSON,
required fields, language coverage, version consistency, Docker-Hub-only image,
fixed tag, port rules, non-root, health check, TZ, restart policy, volume
containment, `x-app-meta` last, no literal secrets) and finally packs a
deterministic `tar.gz` with a `.sha256` next to it.

Official spec check (both packages must print `check passed`):

```bash
./TOSAppSelfTestingTool -c out/privatebindocker_x86_64.tar.gz
./TOSAppSelfTestingTool -c out/privatebindocker_aarch64.tar.gz
```

Runtime verification without touching production data:

```bash
python3 ../../stage.py . --timeout 300     # isolated port + isolated data dir
```

## Data and uninstall

| Path | Content |
|---|---|
| `/Volume1/DockerAppData/privatebindocker/data` | encrypted pastes, comments, attachments, server salt, rate-limit records |
| `/Volume1/DockerAppData/privatebindocker/cfg` | optional `conf.php` |

**Uninstall:** stop the app in the App Center and remove the app together with
its data (the dialog offers it), or delete
`/Volume1/DockerAppData/privatebindocker` manually after removing the app. The
Docker package format has no uninstall hook, so nothing is deleted automatically:
while the folder exists, the ciphertext — and the rate-limit hashes — stay on
disk. Removing the app without removing the folder leaves the data orphaned.

**Backup:** the data folder contains ciphertext only; a backup is useless without
the links that carry the keys.

## Upgrade

The package always ships the latest upstream release. `docker compose` pulls the
pinned tag on (re)install; pastes in `data/` survive a package upgrade because the
volume path does not change. Version 2.1.1 fixes GHSA-6vvp-q86m-cp8q,
GHSA-9rmv-j9gp-6vc5 and GHSA-c4gc-8mcm-hh65 — do not run 2.1.0 or older.

## Limitations

- **HTTPS is required for browser-side encryption.** Browsers expose the WebCrypto
  API (`crypto.subtle`) only in a *secure context*. Opened over plain
  `http://<NAS-IP>:8177`, the page loads but pastes cannot be created or read.
  Use a TLS reverse proxy (or a VPN, or `http://127.0.0.1:8177` on the NAS itself)
  to get a working instance. This is an upstream design constraint, not a
  packaging defect.
- The built-in PHP server is single-threaded; it is fine for personal use and for
  a handful of concurrent users.
- Default retention: one week, maximum one year (`never` is also offered). Change
  it in `conf.php` under the `cfg` folder.
- Plain HTTP on the LAN also means the URL fragment is protected only by the
  browser, not by transport encryption.
- The image is used unmodified; CVE fixes arrive with the next upstream release.

## Licence

Packaging: MIT (see `LICENSE`). Upstream application: Zlib with acknowledgement.
See [NOTICE.md](NOTICE.md).

---

Packaged for TOS 7 by Moechz.
