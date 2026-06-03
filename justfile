set tempdir := "/tmp"
lazarus_dir := env_var_or_default("LAZARUSDIR", env_var_or_default("LAZARUS_DIR", ""))
pcp := env_var_or_default("PASLS_LAZARUS_PCP", ".lazarus")

default:
    @just --list

register:
    #!/usr/bin/env bash
    set -euo pipefail
    lazarus_dir="{{lazarus_dir}}"
    if [[ -z "$lazarus_dir" ]]; then
      echo "LAZARUSDIR or LAZARUS_DIR must be set" >&2
      exit 1
    fi
    pcp="{{pcp}}"
    mkdir -p "$pcp"
    lazbuild --lazarusdir="$lazarus_dir" --pcp="$pcp" \
      --add-package-link "$PWD/src/protocol/lspprotocol.lpk" \
      --add-package-link "$PWD/src/serverprotocol/lspserver.lpk"

build:
    #!/usr/bin/env bash
    set -euo pipefail
    bash "$PWD/src/build_fpc.sh"

test: register
    #!/usr/bin/env bash
    set -euo pipefail
    lazarus_dir="{{lazarus_dir}}"
    pcp="{{pcp}}"
    target_cpu="${FPCTARGETCPU:-$(uname -m)}"
    target_os="${FPCTARGET:-$(uname -s)}"
    case "$target_cpu" in
      amd64) target_cpu="x86_64" ;;
      arm64) target_cpu="aarch64" ;;
    esac
    case "$target_os" in
      Linux) target_os="linux" ;;
      Darwin) target_os="darwin" ;;
    esac
    out_dir="$PWD/dist/$target_cpu-$target_os"
    unit_dir="$PWD/build/$target_cpu-$target_os/test-units"
    mkdir -p "$out_dir" "$unit_dir"
    lazbuild --lazarusdir="$lazarus_dir" --pcp="$pcp" \
      --opt="-FU$unit_dir" \
      --opt="-FE$out_dir" \
      --opt="-o$out_dir/testlsp" \
      "$PWD/src/tests/testlsp.lpi"
    "$out_dir/testlsp"

clean:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf \
      "$PWD/.lazarus" \
      "$PWD/result" \
      "$PWD/build" \
      "$PWD/dist"
