#!/bin/bash

# LibWrt 多设备构建脚本
# 作者：李杰

set -e

# 默认参数
DEFAULT_CONFIG="wrt_core/deconfig/jdcloud_re-ss-01.config"
DEVICE_CONFIG=""
THREADS=$(nproc)

# 显示帮助信息
function show_help() {
    echo "========================================"
    echo "LibWrt 多设备构建脚本"
    echo "========================================"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -d, --dir       指定源码目录 (默认: $SOURCE_DIR)"
    echo "  -c, --config    指定配置文件 (默认: $DEFAULT_CONFIG)"
    echo "  -t, --threads   指定构建线程数 (默认: $THREADS)"
    echo "  -D, --device    指定设备型号 (可选)"
    echo ""
    echo "支持的设备:"
    echo "  jdcloud_re-ss-01    京东云 re-ss-01"
    echo "  link_nn6000-v1      Link NN6000-v1"
    echo "  link_nn6000-v2      Link NN6000-v2"
    echo "  qihoo_360v6         360V6"
    echo "  xiaomi_ax1800       小米 AX1800"
    echo "  zn_m2               ZN M2"
    echo "  cmcc_rax3000m_nand  CMCC RAX3000M (NAND 版本)"
    echo ""
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -c|--config)
            DEFAULT_CONFIG="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -D|--device)
            DEVICE_CONFIG="wrt_core/deconfig/$2.config"
            shift 2
            ;;
        *)
            echo "错误：未知选项 $1"
            show_help
            exit 1
            ;;
    esac
done

# 主构建流程
echo "========================================"
echo "LibWrt 多设备构建脚本"
echo "========================================"

# 为每个设备使用独立的构建目录
if [ -n "$DEVICE_CONFIG" ]; then
    DEVICE_NAME=$(basename "$DEVICE_CONFIG" .config)
    SOURCE_DIR="openwrt-${DEVICE_NAME}"
else
    SOURCE_DIR="openwrt"
fi

# 1. 管理源码
if [ ! -d "$SOURCE_DIR" ]; then
    echo "克隆 LibWrt 源码..."
    git clone --depth 1 --single-branch -b main-nss https://github.com/LiBwrt/openwrt-6.x.git "$SOURCE_DIR"
    cd "$SOURCE_DIR"
else
    echo "更新 LibWrt 源码..."
    cd "$SOURCE_DIR"
    git fetch && git reset --hard origin/main-nss
fi

# 复制 feeds 配置文件
echo "复制 feeds 配置文件..."
cp "../feeds.conf.default" .

# 2. 运行自定义脚本第一部分
echo "运行自定义脚本第一部分..."
if [ -f "../Scripts/diy-part1.sh" ]; then
    bash ../Scripts/diy-part1.sh
else
    echo "警告：未找到 diy-part1.sh 脚本"
fi

# 3. 更新 feeds
echo "更新 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 应用配置
if [ -n "$DEVICE_CONFIG" ]; then
    echo "应用设备配置: $(basename "$DEVICE_CONFIG" .config)"
    if [ -f "../$DEVICE_CONFIG" ]; then
        cp "../$DEVICE_CONFIG" .config
        make defconfig
    else
        echo "错误：未找到设备配置文件 $DEVICE_CONFIG"
        exit 1
    fi
else
    echo "应用默认配置..."
    if [ -f "../$DEFAULT_CONFIG" ]; then
        cp "../$DEFAULT_CONFIG" .config
        make defconfig
    else
        echo "错误：未找到默认配置文件 $DEFAULT_CONFIG"
        exit 1
    fi
fi

# 5. 运行自定义脚本第二部分
echo "运行自定义脚本第二部分..."
if [ -f "../Scripts/diy-part2.sh" ]; then
    bash ../Scripts/diy-part2.sh
else
    echo "警告：未找到 diy-part2.sh 脚本"
fi

# 6. 开始构建
echo "开始构建..."
make -j"$THREADS" V=s

echo "========================================"
echo "构建完成！"
echo "========================================"

