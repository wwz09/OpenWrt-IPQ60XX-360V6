#!/bin/bash

# LibWrt 构建脚本
# 作者：李杰

set -e

echo "========================================"
echo "LibWrt 构建脚本"
echo "========================================"

# 检查环境
if [ ! -d "openwrt" ]; then
    echo "克隆 LibWrt 源码..."
    git clone https://github.com/LibWrt/LibWrt.git openwrt
fi

cd openwrt

# 运行自定义脚本第一部分
echo "运行自定义脚本第一部分..."
if [ -f "../Scripts/diy-part1.sh" ]; then
    bash ../Scripts/diy-part1.sh
else
    echo "警告：未找到 diy-part1.sh 脚本"
fi

# 更新 feeds
echo "更新 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 应用配置
echo "应用配置..."
if [ -f "../wrt_core/deconfig/compile_base.config" ]; then
    cp ../wrt_core/deconfig/compile_base.config .config
    make defconfig
else
    echo "错误：未找到配置文件"
    exit 1
fi

# 运行自定义脚本第二部分
echo "运行自定义脚本第二部分..."
if [ -f "../Scripts/diy-part2.sh" ]; then
    bash ../Scripts/diy-part2.sh
else
    echo "警告：未找到 diy-part2.sh 脚本"
fi

# 开始构建
echo "开始构建..."
make -j$(nproc) V=s

echo "========================================"
echo "构建完成！"
echo "========================================"
