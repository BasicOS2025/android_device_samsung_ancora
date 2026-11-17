#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_WORKSPACE:?Run this script in its GitHub Actions workflow}"
: "${RUNNER_TEMP:?Runner temporary directory is required}"
: "${GITHUB_SHA:?The device source revision is required}"
rom_root="$RUNNER_TEMP/ancora-lineage-15.1"
rom_logs="$GITHUB_WORKSPACE/build-logs"
rom_artifacts="$GITHUB_WORKSPACE/rom-artifacts"
rom_tools="$RUNNER_TEMP/ancora-build-tools"
mkdir -p "$rom_root" "$rom_logs" "$rom_artifacts" "$rom_tools"

progress() {
    local percent="$1"
    local phase="$2"
    printf '[Ancora progress] %s%% - %s\n' "$percent" "$phase"
    printf '::notice title=Ancora build progress::Estimated %s%% - %s\n' "$percent" "$phase"
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        {
            printf '### Ancora ROM build progress\n\n'
            printf '**Estimated: %s%%** — %s\n\n' "$percent" "$phase"
        } > "$GITHUB_STEP_SUMMARY"
    fi
}

progress 5 'Runner and build directories prepared'

finish() {
    local result=$?
    printf 'Exit code: %s\n' "$result" > "$rom_logs/result.txt"
    df -h >> "$rom_logs/result.txt"
}
trap finish EXIT

free_kib=$(df -Pk "$rom_root" | awk 'NR==2 {print $4}')
if (( free_kib < 50 * 1024 * 1024 )); then
    echo 'Insufficient runner disk: at least 50 GiB free is needed to attempt this build.'
    exit 1
fi
java -version
python2 --version
git config --global user.name 'Ancora ROM Builder'
git config --global user.email 'ancora-build@users.noreply.github.com'
curl --fail --location --retry 3 https://storage.googleapis.com/git-repo-downloads/repo -o "$rom_tools/repo"
chmod +x "$rom_tools/repo"
ln -sf "$(command -v python2)" "$rom_tools/python"
export PATH="$rom_tools:$PATH"
export LC_ALL=C
export LANG=C
export PYTHONHASHSEED=0
export USE_CCACHE=1
export CCACHE_DIR="$RUNNER_TEMP/ancora-ccache"
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 4G
build_jobs=$(nproc)
if (( build_jobs > 4 )); then
    build_jobs=4
fi

# Jack's legacy loopback TLS endpoint needs TLSv1 on current Java 8 updates.
# Retain all other algorithm restrictions and limit this override to Jack's JVM.
jack_security="$rom_tools/jack.security"
python3 - "$JAVA_HOME" "$jack_security" <<'PY'
import re
import sys
from pathlib import Path
root = Path(sys.argv[1])
security = next(p for p in (root / 'jre/lib/security/java.security',
                            root / 'lib/security/java.security') if p.is_file())
text = re.sub(r'\\\r?\n\s*', '', security.read_text())
match = re.search(r'^jdk.tls.disabledAlgorithms\s*=\s*(.*)$', text, re.M)
if not match:
    raise SystemExit('Java TLS algorithm policy not found')
algorithms = [part.strip() for part in match[1].split(',')]
algorithms = [part for part in algorithms if part not in ('TLSv1', 'TLSv1.1')]
Path(sys.argv[2]).write_text('jdk.tls.disabledAlgorithms=' + ', '.join(algorithms) + '\n')
PY

cd "$rom_root"
python3 "$rom_tools/repo" init \
    -u https://github.com/LineageOS/android.git -b lineage-15.1 \
    --depth=1 -g default,-darwin --no-clone-bundle
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/ancora.xml <<XML
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="ancora-public" fetch="https://github.com/BasicOS2025/" />
  <project name="android_device_samsung_ancora" path="device/samsung/ancora" remote="ancora-public" revision="$GITHUB_SHA" />
  <project name="android_vendor_samsung_ancora" path="vendor/samsung/ancora" remote="ancora-public" revision="6a2990b5c3a60de87dcb6d16dc5cb596d7ff8051" />
  <project name="android_kernel_samsung_msm7x30-common" path="kernel/samsung/msm7x30-common" remote="ancora-public" revision="40d204ae063b61956fa578dd6a389b2022fe2c9e" />
</manifest>
XML
cp .repo/local_manifests/ancora.xml "$rom_logs/ancora-manifest.xml"
python3 "$rom_tools/repo" manifest -o "$rom_logs/requested-manifest.xml"
python3 "$rom_tools/repo" sync -c --no-tags --no-clone-bundle --fail-fast -j6
python3 "$rom_tools/repo" manifest -r -o "$rom_logs/resolved-manifest.xml"
progress 20 'LineageOS sources synchronized'

# Old Android build scripts expect Python 2; repo itself runs with Python 3.
set +u
source build/envsetup.sh
lunch lineage_ancora-userdebug
set -u
progress 25 'Build environment configured'

# Reuse this runner's downloaded sources when a reviewed device fix is pushed.
# Only fast-forward commits from the same public lineage-15.1 branch are accepted.
device_checkout="$rom_root/device/samsung/ancora"
device_remote=https://github.com/BasicOS2025/android_device_samsung_ancora.git
build_result=1
for build_attempt in $(seq 1 20); do
    device_revision=$(git -C "$device_checkout" rev-parse HEAD)
    printf '%s\n' "$device_revision" > "$rom_logs/device-revision.txt"
    printf 'Build attempt %s, device revision %s\n' "$build_attempt" "$device_revision"
    progress 25 "Compiling ROM (attempt $build_attempt/20)"
    python3 "$rom_tools/repo" manifest -r -o "$rom_logs/resolved-manifest.xml"
    set +e
    # This kernel has been compiled with GCC 4.8. Keep the same target toolchain.
    make -j"$build_jobs" bacon \
        KERNEL_TOOLCHAIN="$rom_root/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin" \
        KERNEL_TOOLCHAIN_PREFIX=arm-eabi- \
        ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx3g -Djava.security.properties=$jack_security" \
        'MAKE_FLAGS=HOSTCFLAGS="-O2 -fcommon"' \
        WITH_DEXPREOPT=false 2>&1 | tee "$rom_logs/attempt-$build_attempt.log"
    build_result=${PIPESTATUS[0]}
    set -e
    if (( build_result == 0 )); then
        progress 85 'ROM compilation completed; collecting artifacts'
        break
    fi
    python3 "$GITHUB_WORKSPACE/ci/report-failure.py" "$rom_logs"
    if (( build_attempt == 20 )); then
        exit "$build_result"
    fi
    echo 'Build failed. Waiting up to 10 minutes for a device fix on lineage-15.1.'
    new_revision="$device_revision"
    for revision_poll in $(seq 1 20); do
        sleep 30
        new_revision=$(git ls-remote "$device_remote" refs/heads/lineage-15.1 | cut -f1)
        if [[ -n "$new_revision" && "$new_revision" != "$device_revision" ]]; then
            break
        fi
    done
    if [[ -z "$new_revision" || "$new_revision" == "$device_revision" ]]; then
        exit "$build_result"
    fi
    git -C "$device_checkout" fetch --depth=50 "$device_remote" refs/heads/lineage-15.1
    git -C "$device_checkout" merge --ff-only FETCH_HEAD
done
if (( build_result != 0 )); then
    exit "$build_result"
fi

python3 "$device_checkout/ci/collect-rom.py" \
    "$rom_root/out/target/product/ancora" "$rom_artifacts"
progress 95 'ROM ZIP and checksums collected'
cp "$rom_logs/resolved-manifest.xml" "$rom_artifacts/"
printf 'ROM compiled successfully; physical-device boot has not been tested.\n' > "$rom_artifacts/BUILD-NOTES.txt"
