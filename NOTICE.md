# Notices and third-party components

Package: **PrivateBin for TerraMaster TOS 7**, app id `privatebindocker`,
version `2.1.1-3`.

## Upstream application

- Project: **PrivateBin** — <https://github.com/PrivateBin/PrivateBin>
- Version shipped: **2.1.1** (released 2026-11-04)
- Licence: **Zlib licence with acknowledgement** (`zlib-acknowledgement`), see
  <https://github.com/PrivateBin/PrivateBin/blob/master/LICENSE.md>
- Copyright: the PrivateBin contributors (2012 Sébastien Sauvage and others).

No upstream source code is redistributed in this repository: the application is
delivered exclusively through the official container image (below), and this
repository contains only packaging files.

## Container image

- Image: **`privatebin/nginx-fpm-alpine:2.1.1`** (Docker Hub, official project
  image from <https://github.com/PrivateBin/docker-nginx-fpm-alpine>), used
  unmodified, digest
  `sha256:9fbcc4d5671b974cafb55948d6fc3ab9eaf77f0c39271a50a16dd71bd4c4d3e6`
  (multi-architecture: `linux/amd64`, `linux/arm64`).
- Base: Alpine Linux 3.24.3, nginx 1.30.6, PHP 8.5.12 (php-fpm, gd, iconv,
  mysqlnd, openssl, pdo_mysql, pdo_pgsql, simplexml).
- The image is pulled from Docker Hub at install time; the tag is fixed (never
  `:latest`) and the digest above is what this package was built and tested
  against.

Client-side components bundled inside that image (served from the container, no
CDN involved): Bootstrap 5.3.8, DOMPurify 3.4.17, showdown 2.1.0, base-x 5.0.1,
kjua 0.10.0, zlib 1.3.2 (WASM), google-code-prettify. Their licences are the ones
declared by their respective projects (MIT / Apache-2.0 / BSD / Zlib); they are
redistributed unmodified as part of the upstream image.

## This packaging

- The packaging files in this repository (`tosapp.json`, `src/`, `scripts/`,
  `tools/`, `test/`, documentation) are **MIT licensed**, © 2026 Moechz — see
  `LICENSE`.
- The packaging adds no third-party code of its own.

## Trademarks

- **PrivateBin** and the PrivateBin logo are trademarks of the upstream project.
- **TerraMaster**, **TOS** and the TerraMaster logo are trademarks of TerraMaster.
- This is an independent community submission by Moechz. It is not produced,
  endorsed or supported by the PrivateBin project or by TerraMaster.

## Security advisories addressed by the shipped version

PrivateBin 2.1.1 fixes:

- GHSA-6vvp-q86m-cp8q — SVG attachment preview could run same-origin script
- GHSA-9rmv-j9gp-6vc5 — `sizelimit` circumvention allowed a disk-filling DoS
- GHSA-c4gc-8mcm-hh65 — the Markdown sanitisation fix in 2.1.0 was ineffective
- GHSA-hw9p-r7fq-8mvr — unauthenticated comment replay could reparent comments

Older releases (2.1.0 and earlier) must not be used.
