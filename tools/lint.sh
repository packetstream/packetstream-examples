#!/usr/bin/env bash
# Lint one example with the usual tools for its language.
#
# Usage: tools/lint.sh <example-dir>
#
# Linters run in Docker, apart from shellcheck, so the only host requirements
# are Docker and shellcheck. Building the image is a separate step; the Java
# and C# builds also fail on compiler warnings.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <example-dir>" >&2
  exit 2
fi

root=$(cd "$(dirname "$0")/.." && pwd)
dir=${1%/}
cd "$root/$dir"

ruff_image=ghcr.io/astral-sh/ruff:0.17.3
golangci_image=golangci/golangci-lint:v2.15.0-alpine
phpstan_image=ghcr.io/phpstan/phpstan:2.3.1

run() {
  echo "+ $*" >&2
  "$@"
}

ran=0

if compgen -G '*.sh' >/dev/null; then
  run shellcheck ./*.sh
  ran=1
fi

if compgen -G '*.py' >/dev/null; then
  run docker run --rm -v "$PWD":/src:ro -w /src "$ruff_image" \
    check --no-cache --select E,F,I,B,UP --line-length 120 .
  run docker run --rm -v "$PWD":/src:ro -w /src "$ruff_image" \
    format --no-cache --check --line-length 120 .
  ran=1
fi

if [ -f go.mod ]; then
  # Mount the repository so the shared .golangci.yml is available.
  run docker run --rm -v "$root":/repo:ro -w "/repo/$dir" \
    -e GOFLAGS=-buildvcs=false -e GOCACHE=/tmp/go-cache -e GOLANGCI_LINT_CACHE=/tmp/lint-cache \
    "$golangci_image" sh -c \
    'golangci-lint run --config /repo/.golangci.yml ./... && golangci-lint fmt --config /repo/.golangci.yml --diff ./...'
  ran=1
fi

if [ -f package.json ]; then
  for file in *.js; do
    run docker run --rm -v "$PWD":/src:ro -w /src node:26-alpine node --check "$file"
  done
  ran=1
fi

if [ -f Cargo.toml ]; then
  run docker run --rm -v "$PWD":/src:ro -w /src -e CARGO_TARGET_DIR=/tmp/target rust:1.99 sh -c \
    'rustup component add rustfmt clippy >/dev/null 2>&1 && cargo fmt --check && cargo clippy --locked -- -D warnings'
  ran=1
fi

if compgen -G '*.php' >/dev/null; then
  for file in *.php; do
    run docker run --rm -v "$PWD":/app:ro -w /app php:8.5-cli-alpine php -l "$file"
  done
  if [ -f phpstan.neon ]; then
    run docker run --rm -v "$PWD":/app:ro -w /app "$phpstan_image" analyse --no-progress
  fi
  ran=1
fi

if [ -f Gemfile ]; then
  run docker run --rm -v "$PWD":/src:ro -w /src -e HOME=/tmp -e BUNDLE_FROZEN=true -e BUNDLE_APP_CONFIG=/tmp/bundle \
    ruby:4.0-alpine sh -c \
    'apk add --no-cache build-base >/dev/null && bundle install --quiet && bundle exec rubocop --cache false'
  ran=1
fi

if compgen -G '*.csproj' >/dev/null; then
  # dotnet format writes bin/ and obj/, so lint a copy.
  run docker run --rm -v "$PWD":/src:ro mcr.microsoft.com/dotnet/sdk:10.0 sh -c \
    'cp -r /src /tmp/src && cd /tmp/src && dotnet format --verify-no-changes'
  ran=1
fi

if compgen -G '*.java' >/dev/null; then
  echo "Java is linted by its Docker build (javac -Xlint:all -Werror)" >&2
  ran=1
fi

if [ "$ran" -eq 0 ]; then
  echo "No linter matched $dir" >&2
  exit 1
fi

echo "LINT OK $dir"
