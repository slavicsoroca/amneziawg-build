#!/bin/bash
# Build AmneziaWG packages for Redmi AX3000 (hzyitc ipq50xx kernel 5.15.150)
# Run this script inside WSL Ubuntu

set -e

SDK_URL="https://github.com/hzyitc/openwrt-redmi-ax3000/releases/download/ci-ipq50xx-mainline-kernel-5.15-openwrt-23.05-20240724-153345-UTC/openwrt-sdk-ipq50xx-arm_gcc-12.3.0_musl_eabi.Linux-x86_64.tar.xz"
BUILD_DIR="$HOME/amneziawg-build"

echo "=== Installing build dependencies ==="
sudo apt-get update -qq
sudo apt-get install -y \
    build-essential libncurses5-dev python3 python3-distutils \
    unzip wget git rsync zlib1g-dev gawk gettext libssl-dev \
    file quilt

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== Downloading hzyitc SDK ==="
if [ ! -f sdk.tar.xz ]; then
    wget -q --show-progress "$SDK_URL" -O sdk.tar.xz
fi

echo "=== Extracting SDK ==="
tar xf sdk.tar.xz
SDK_DIR=$(ls -d openwrt-sdk-*/ | head -1)
cd "$SDK_DIR"

echo "=== Adding AmneziaWG feed ==="
echo "src-git amneziawg https://github.com/amnezia-vpn/amneziawg-openwrt.git" >> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a

echo "=== Configuring packages ==="
cat >> .config << 'EOF'
CONFIG_PACKAGE_kmod-amneziawg=m
CONFIG_PACKAGE_amneziawg-tools=y
CONFIG_PACKAGE_luci-proto-amneziawg=y
EOF
make defconfig

echo "=== Building packages ==="
make package/kmod-amneziawg/compile -j$(nproc) V=s
make package/amneziawg-tools/compile -j$(nproc) V=s
make package/luci-proto-amneziawg/compile -j$(nproc) V=s

echo "=== Collecting .ipk files ==="
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
mkdir -p "$ARTIFACTS_DIR"
find bin/ -name "*.ipk" | grep -E "amnezia|awg" | while read f; do
    echo "Found: $f"
    cp "$f" "$ARTIFACTS_DIR/"
done

echo ""
echo "=== BUILD COMPLETE ==="
echo "Packages in: $ARTIFACTS_DIR"
ls -la "$ARTIFACTS_DIR/"
