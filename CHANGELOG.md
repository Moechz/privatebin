# Changelog

All notable user-visible changes to the PrivateBin TOS application package.

## 2.1.1-3 — 2026-11-22

Remediation of the App Center review findings for 2.1.1-2
(tracking checklist TOS-APP-CL-20261121-01). Upstream stays at **2.1.1**, the
latest release.

### Fixed
- **P2 — dead help link.** `config.ini` `help` pointed to a repository that does
  not exist (HTTP 404). It now points to the public privacy policy
  `https://github.com/Moechz/privatebin/blob/main/PRIVACY.md`, which opens
  anonymously (no sign-in).
- **F3 — service did not stop cleanly.** The web server was `exec`'ed into PID 1,
  and a PID 1 process gets no default signal handling, so `docker stop` waited out
  the whole grace period and the container was SIGKILLed. The wrapper now runs the
  server as a child, forwards `SIGTERM`/`SIGINT`, waits for it to exit and reports
  a clean stop (`stop_grace_period: 20s` added as a safety net).
- **C10 — repository and directory compliance.** README rewritten with
  *Repository layout*, *How it works*, *Privacy*, *Notices*, *Build*,
  *Data and uninstall*, *Upgrade* and *Limitations*; the repository is public and
  every file in it is described there.

### Added (C3 / C4 / C5 / C6 / C7)
- **`PRIVACY.md`** written from scratch for this application, covering everything
  the reviewers asked for: the data actually stored (ciphertext, parameters,
  paste IDs, hashed rate-limit records), the storage location and the optional
  storage backends, the retention of pastes/comments/attachments/rate-limit
  records/logs, the server log content and its 3 × 10 MiB cap, cookies and browser
  storage, the third-party table (none by default; the optional shortener, SMTP,
  S3 and database backends when configured), the security measures, the user
  rights and the deletion channel, and a contact address. The help link in
  `config.ini` points at it, so it is reachable from inside the package and over a
  public URL.
- **`NOTICE.md`** with the upstream licence (Zlib with acknowledgement), the image
  digest, the bundled client-side libraries and the trademark attribution.
  `LICENSE` stays MIT for the packaging.
- **`cfg` volume**: `/Volume1/DockerAppData/privatebindocker/cfg` is now mounted at
  `/srv/cfg`, so an optional `conf.php` (retention, size limit, storage backend)
  can be dropped in — the policy documents the default retention instead of
  leaving it implicit.
- Docker log cap (`json-file`, 10 MiB × 3) so request logs — which contain the
  client IP and the paste ID in the URL — do not grow without bound.

### Changed (C9 / F5 / F7)
- Descriptions (en / zh-cn / zh-hk) rewritten to match the delivered features and
  to state the HTTPS requirement of browser-side encryption: the client uses the
  WebCrypto API, which browsers only expose in a secure context, so over plain
  `http://<NAS-IP>:8177` the page loads but pastes cannot be created or read. The
  workaround (TLS reverse proxy, VPN, or `http://127.0.0.1:8177` on the NAS) is
  documented in the listing text, README and PRIVACY; the limitation comes from
  upstream and cannot be fixed inside the package while the App Center publishes
  plain HTTP.
- **T1**: the base image is the latest upstream release 2.1.1 (2026-11-04), which
  fixes GHSA-6vvp-q86m-cp8q, GHSA-9rmv-j9gp-6vc5, GHSA-c4gc-8mcm-hh65 and
  GHSA-hw9p-r7fq-8mvr, and ships the current Alpine 3.24.3 / PHP 8.5.12 /
  nginx 1.30.6 base. No newer upstream release exists as of 2026-11-22; the image
  digest is pinned in `NOTICE.md` and the next upstream release will be adopted in
  the following package version.

## 2.1.1-2 — 2026-11-21

### Changed
- Packaging iteration only: repository metadata and submission fixes
  (x86_64 published, aarch64 submitted).

## 2.1.1-1 — 2026-11-15

### Added
- First release. PrivateBin (`privatebin/nginx-fpm-alpine:2.1.1`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8177 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/privatebindocker/`.
