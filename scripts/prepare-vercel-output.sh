#!/usr/bin/env bash
set -euo pipefail

mkdir -p .vercel/output/static
find .vercel/output -mindepth 1 -delete
mkdir -p .vercel/output/static
cp -R build/web/. .vercel/output/static/
printf '%s\n' '{"version":3,"routes":[{"handle":"filesystem"},{"src":"/.*","dest":"/index.html"}]}' > .vercel/output/config.json
