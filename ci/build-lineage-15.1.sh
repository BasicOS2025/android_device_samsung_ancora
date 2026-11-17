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
unset USE_CCACHE || true

cd "$rom_root"
python3 "$rom_tools/repo" init \
    -u https://github.com/LineageOS/android.git -b lineage-15.1 \
    --depth=1 -g default,-darwin,-cts --no-clone-bundle
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/ancora.xml <<XML
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="ancora-public" fetch="https://github.com/BasicOS2025/" />
  <project name="android_device_samsung_ancora" path="device/samsung/ancora" remote="ancora-public" revision="$GITHUB_SHA" />
  <project name="android_vendor_samsung_ancora" path="vendor/samsung/ancora" remote="ancora-public" revision="2e972f80e736ada25946ce1f116e49f3f4ff451c" />
  <project name="android_kernel_samsung_msm7x30-common" path="kernel/samsung/msm7x30-common" remote="ancora-public" revision="f5c456682c0577245467637c0a2726d3fcbdb256" />
</manifest>
XML
cp .repo/local_manifests/ancora.xml "$rom_logs/ancora-manifest.xml"
python3 "$rom_tools/repo" manifest -o "$rom_logs/requested-manifest.xml"
python3 "$rom_tools/repo" sync -c --no-tags --no-clone-bundle --fail-fast -j4
python3 "$rom_tools/repo" manifest -r -o "$rom_logs/resolved-manifest.xml"

# Old Android build scripts expect Python 2; repo itself runs with Python 3.
set +u
source build/envsetup.sh
lunch lineage_ancora-userdebug
set -u

# This kernel has been compiled with GCC 4.8. Keep the same target toolchain.
make -j3 bacon \
    KERNEL_TOOLCHAIN="$rom_root/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin" \
    KERNEL_TOOLCHAIN_PREFIX=arm-eabi- \
    'MAKE_FLAGS=HOSTCFLAGS="-O2 -fcommon"' \
    WITH_DEXPREOPT=false

python3 "$GITHUB_WORKSPACE/ci/collect-rom.py" \
    "$rom_root/out/target/product/ancora" "$rom_artifacts"
cp "$rom_logs/resolved-manifest.xml" "$rom_artifacts/"
printf 'ROM compiled successfully; physical-device boot has not been tested.\n' > "$rom_artifacts/BUILD-NOTES.txt"
