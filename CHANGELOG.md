# Changelog

All notable user-visible changes to the PrivateBin TOS application package.

## 2.1.1-1 — 2026-11-15

### Added
- First release. PrivateBin (`privatebin/nginx-fpm-alpine:2.1.1`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8177 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/privatebindocker/`.
