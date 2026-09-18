#!/bin/sh
# Fixture for the sh workflow: shellcheck and shfmt both have something to read.
set -eu

greet() {
  printf 'hello, %s\n' "$1"
}

greet "${1:-world}"
