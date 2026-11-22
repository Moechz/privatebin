# Privacy Policy — PrivateBin for TerraMaster TOS

Last updated: 2026-11-22

- **App ID:** `privatebindocker`
- **Package:** PrivateBin for TerraMaster TOS 7 (package version 2.1.1-3)
- **Publisher:** Moechz
- **Package source:** <https://github.com/Moechz/privatebin>
- **Upstream project:** <https://github.com/PrivateBin/PrivateBin> (Zlib licence)
- **Container image:** `privatebin/nginx-fpm-alpine:2.1.1` from Docker Hub, used unmodified

This document is the privacy policy the App Center help link points to. It
describes **what this package stores on your NAS, where, for how long, who can
read it, and how to delete it**.

## 1. Scope and data controller

PrivateBin is a **self-hosted** application. It runs entirely on the NAS where
the App Center installed it, inside the NAS owner's Docker engine. The publisher
does not operate any hosted PrivateBin service, does not receive pastes, keys,
logs or telemetry, and has no access to your NAS.

The person or organisation that installs and administers the NAS is the **data
controller** for everything the app stores. The publisher is only the packager
of the Docker application archive.

## 2. What the app processes

A paste is encrypted in the browser before it is sent. The server therefore
never sees the text you paste, the password you may set, or the decryption key.

| Data | Where it comes from | Stored on the NAS? |
|---|---|---|
| Paste body (**ciphertext**, Base64) | browser | yes, in the paste file |
| Comments (ciphertext), including nickname if one is typed | browser | yes, in the same paste file |
| Attachments (ciphertext, Base64, max 10 MiB by default) | browser | yes, in the same paste file |
| Encryption parameters: IV, salt, iteration count, key size, tag size, cipher + mode, compression, format version | browser | yes, in the paste file (needed to decrypt later) |
| Paste ID (22 random characters) and, for discussions, comment IDs | server | yes, in the paste file |
| Expiry setting (`5min` … `never`) and creation time | browser + server | yes, in the paste file |
| Delete token | server | only its one-way hash is kept |
| Decryption key / passphrase | **browser only** | **no — never sent to the server** |
| Client IP address | network | not in clear text: only a salted HMAC used for rate limiting (see §6) |
| Request log lines (IP:port, time, method, URL, status) | web server | in the container log (see §7) |

No name, e-mail address, phone number or account is requested. The app has **no
user accounts**, no sign-up, no analytics, no advertising, no crash reporting,
no telemetry and no "phone home" call. Nothing about your usage is sent to the
publisher.

## 3. End-to-end encryption and key handling

The zero-knowledge property is provided by the upstream web client and works
like this:

- The browser generates a random 256-bit key; the optional password is mixed in
  with **PBKDF2-HMAC-SHA256, 100 000 iterations** and a random 8-byte salt.
- The text is compressed (zlib) and encrypted with **AES-256-GCM** using a random
  16-byte IV and authenticated data that binds the ciphertext to its parameters.
- The key (and password material) is placed in the **URL fragment** — the part
  after `#` in the generated link. Browsers never send the fragment to a server,
  so the key never reaches the NAS.
- The server receives only the ciphertext plus the parameters listed in §2. It
  has no way to decrypt a paste, and it cannot tell whether a comment password
  was correct.
- **The link is the secret.** Anyone who has a complete link can open the paste,
  subject to its expiry/password/burn-after-reading settings. Share links over a
  channel you trust.

**Secure context requirement.** The client uses the browser **WebCrypto API**
(`crypto.subtle`). Browsers only expose that API on a *secure origin* —
`https://…`, or `http://127.0.0.1` / `http://localhost` on the machine itself.
Opened over plain `http://<NAS-IP>:8177`, the page still loads but the browser
blocks encryption, so pastes can be neither created nor decrypted. Put the app
behind a TLS reverse proxy (or a VPN) if you want to use it from other devices;
see `README.md` → *Limitations*.

## 4. Storage location and backends

- Pastes live in **`/srv/data`** inside the container, which is the NAS folder
  **`/Volume1/DockerAppData/privatebindocker/data`**. Each paste is one file
  named after its random ID, containing the ciphertext and its metadata.
- `/srv/data/salt.php` holds a random per-instance server salt (see §6).
- `/srv/data/traffic_limiter.php` holds the rate-limit records (see §6).
- **`/srv/cfg`** → **`/Volume1/DockerAppData/privatebindocker/cfg`** is the
  configuration folder. It is empty by default; if you add a `conf.php` there
  you can change the storage backend (`Filesystem` is the default; `Database`,
  `S3Storage` and `GoogleCloudStorage` are supported upstream), the size limit,
  the allowed expiry values and the discussion/e-mail features.
- The container itself keeps no data outside these two folders and its
  ephemeral `/tmp`, which is discarded whenever the container is recreated.
- Only ciphertext is written. A backup of the data folder is a backup of
  ciphertext and is useless without the links (which hold the keys).

## 5. Retention and deletion

The app is designed for short-lived data. Nothing is kept "forever" unless you
choose `never` as the expiry.

| Item | Retention |
|---|---|
| Paste / discussion / attachment | until the chosen expiry: `5min`, `10min`, `1hour`, `1day`, `1week` (default), `1month`, `1year`, or `never` if the creator picked it |
| Burn-after-reading paste | deleted on the first successful read, whichever comes first |
| Comment | same expiry as its paste |
| Expired pastes | purged automatically on write operations (upkeep runs at most once every 5 minutes); a paste may therefore exist slightly longer than its nominal expiry |
| Rate-limit record (§6) | deleted 10 minutes after the last recorded post |
| Container log (§7) | rotated by Docker (this package caps it at 3 × 10 MiB, i.e. ≈ 30 MiB) |

Deletion is immediate and permanent: there is no recycle bin and no backup copy
made by the app.

- **Delete one paste before it expires:** open the delete link that the app shows
  right after creating the paste (`?pasteid=…&deletetoken=…`). The token is
  required, and the server stores only its hash, so keep that link.
- **Delete everything:** stop the app in the App Center and remove
  `/Volume1/DockerAppData/privatebindocker` (or choose to delete the data when
  uninstalling). Every paste, comment, salt and rate-limit record is gone.
- **Delete a single paste as administrator:** remove its file from the `data`
  folder (the file name is the paste ID).

## 6. IP addresses and rate limiting

To stop abuse, PrivateBin limits how often one client may post (10 posts per
10 minutes by default). For that it computes

`HMAC-SHA256(client IP, per-instance random server salt)`

and stores only that 64-character hash plus a timestamp in
`data/traffic_limiter.php`. The raw IP address is **not** written to the data
folder. Because the salt (`data/salt.php`) is random per installation and not
shared, the hash cannot be re-identified by comparing it with another
installation. The record is removed by the rate limiter once it is older than
the limit window.

## 7. Server logs

The container writes request lines to stdout/stderr, which the Docker runtime on
the NAS collects (`docker logs privatebindocker`). A line looks like

```
172.17.0.1:51234 [200]: POST /
```

and contains the client IP:port, the timestamp, the HTTP method, the request URL
and the status code. Because a paste is opened through its ID in the URL
(`/?<paste-id>`), those lines link an IP address to *which* paste was created or
read, and when. They never contain paste content, keys or passwords.

- The package caps this log with Docker's `json-file` driver at **10 MiB × 3
  files ≈ 30 MiB**, after which older lines are discarded.
- You can clear it at any time with `docker logs` tooling or by recreating the
  container; you can also disable it (see the Docker documentation for the
  `logging` driver) if you do not want request logs at all.
- Log lines stay on your NAS. Nothing is shipped anywhere by the app.

## 8. Cookies and browser-side storage

- The web UI sets two preference cookies, `lang` and `template`, so that it
  remembers your language and template choice. They contain no identifier and
  expire after one year.
- The browser history stores the URLs of pastes you opened, including the key
  fragment, so treat a shared browser profile as sensitive.
- No tracking cookie, fingerprinting script or third-party resource is used.
- The page loads **only files served by this container** (its own CSS, JS and the
  zlib WASM module). The upstream Content-Security-Policy sent with the page is
  `default-src 'none'` with local origins only, so third-party content cannot be
  loaded even by accident.

## 9. Third parties and outbound connections

**Default configuration: none.** The stock instance does not contact any
external service — no CDN, no font server, no analytics, no update check, no
e-mail gateway. The only connections involved in running the package are:

| Endpoint | When | Data sent | Region |
|---|---|---|---|
| `docker.io` (Docker Hub) | install / update of the app | image pull request (the NAS IP and Docker client metadata, as with any image pull) | whichever registry mirror your NAS uses |
| `github.com` (package source, this policy) | when a human opens the links in this document | ordinary web request from the reader, not from the NAS | global |

Optional features that you can switch on yourself in
`/Volume1/DockerAppData/privatebindocker/cfg/conf.php` do send data to
third parties, and the app's UI warns about them:

| Optional feature | Endpoint | Data sent | Note |
|---|---|---|---|
| URL shortener (Yourls / Shlink / Chhoto URL) | the server you configure | the **complete paste link, including the key fragment** | anyone with access to the shortener's logs can read the paste; off by default for that reason |
| "Send by e-mail" button | *none by default* | — | it opens your own mail client with a `mailto:` link; the app does not send mail unless SMTP is configured in `conf.php` |
| S3 / Google Cloud Storage backend | the bucket you configure | paste ciphertext | only if you change `model.class`; off by default |
| Database backend | the database you configure | paste ciphertext | only if you change `model.class`; off by default |

The package itself never calls home and contains no code that transmits data to
the publisher.

## 10. Security measures

- **Encryption in the browser**: AES-256-GCM, PBKDF2-HMAC-SHA256 with 100 000
  iterations; keys stay in the URL fragment and never reach the server.
- The container runs as **uid 1000:1000**, never as root; no `privileged`, no
  `network_mode: host`, no Docker socket, no added capabilities.
- Only the web port (8177) is published; nothing else is exposed.
- Persistent data is confined to `/Volume1/DockerAppData/privatebindocker/`.
- Fixed image tag (`2.1.1`, never `:latest`), digest recorded in `NOTICE.md`;
  the image is used unmodified from Docker Hub.
- Paste IDs are random 22-character identifiers; delete tokens are not stored
  in clear text; the server salt is random per installation.
- The upstream Content-Security-Policy, output escaping and DOMPurify
  sanitisation are in effect.
- Version 2.1.1 fixes the upstream SVG-preview script execution
  (GHSA-6vvp-q86m-cp8q), the size-limit disk-filling issue
  (GHSA-9rmv-j9gp-6vc5) and the ineffective Markdown sanitisation
  (GHSA-c4gc-8mcm-hh65). Older PrivateBin releases must not be used.
- **Transport:** the App Center publishes plain HTTP on the LAN. The link
  fragment is never sent to the server, but the paste ID and any traffic are
  visible to anyone on the path. Use a TLS reverse proxy or VPN before exposing
  the app beyond your trusted network; HTTPS is also *required* for browser-side
  encryption to work at all (§3).

## 11. Your rights and the deletion channel

The app has no accounts, so there is no server-side identity to export or
correct. You exercise your rights directly:

- **Access:** a paste is readable through its link. The NAS administrator can see
  which paste files exist (metadata only, no plaintext) in
  `/Volume1/DockerAppData/privatebindocker/data`.
- **Rectification:** paste content cannot be edited by design (it is encrypted
  and content-addressed by ID); delete the paste and create a new one.
- **Erasure:** delete a single paste with its delete link, or delete its file, or
  remove `/Volume1/DockerAppData/privatebindocker` to erase everything —
  including the rate-limit hashes, the salts and the configuration.
- **Logs:** clear the container log at any time (see §7).
- **Portability:** nothing is tied to a person, so there is nothing to export
  besides the links you already hold.

Deletion channel and contact for data-protection questions about **this package**:
open an issue at <https://github.com/Moechz/privatebin/issues> (public, no sign-in
needed to read). For data held on a NAS, the NAS administrator is the party that
can act on it. For the upstream application, use
<https://github.com/PrivateBin/PrivateBin>.

## 12. Children

The app is a general-purpose paste tool for NAS administrators and is not
directed at children.

## 13. Changes to this policy

This policy is versioned with the package. Material changes are published in
this file (which is the App Center help link) and summarised in `CHANGELOG.md`;
the "Last updated" date at the top changes at the same time.
