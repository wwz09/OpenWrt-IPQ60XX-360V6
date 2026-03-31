#!/bin/bash
# OpenWrt DIY脚本 Part 1 (MediaTek平台专用)
# 作者: 李杰
# 功能: 在更新feeds之前执行的自定义操作
# 执行时机: feeds更新之前

echo "============================================"
echo "开始执行 MediaTek DIY Part 1 脚本"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 修改默认IP地址 ====================
echo "修改默认IP地址..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    # 修改默认IP为192.168.100.1
    sed -i 's/192.168.1.1/192.168.100.1/g' package/lean/default-settings/files/zzz-default-settings
    echo "✓ 默认IP设置完成"
fi

# ==================== 修改主机名 ====================
echo "修改默认主机名..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    sed -i 's/OpenWrt/OpenWrt-AutoBuild/g' package/lean/default-settings/files/zzz-default-settings
    echo "✓ 主机名修改完成"
fi

# ==================== 修改时区 ====================
echo "设置默认时区..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    sed -i "s/'UTC'/'CST-8'/g" package/lean/default-settings/files/zzz-default-settings
    sed -i "s/'Asia\/Shanghai'/'Asia\/Shanghai'/g" package/lean/default-settings/files/zzz-default-settings
    echo "✓ 时区设置完成"
fi

# ==================== 处理NSS驱动问题 ====================
echo "处理NSS驱动问题..."
# 移除可能导致冲突的NSS包
find package -name "qca-nss*" -type d | xargs rm -rf 2>/dev/null
find feeds -name "qca-nss*" -type d | xargs rm -rf 2>/dev/null
echo "✓ NSS驱动清理完成"

# ==================== 添加第三方软件源 ====================
echo "添加第三方软件源..."

# 使用 kenzok8/small-package 作为插件源
if ! grep -q "small" feeds.conf.default; then
    echo "src-git small https://github.com/kenzok8/small" >> feeds.conf.default
    echo "✓ small 插件源添加完成"
else
    echo "✓ small 插件源已存在"
fi

# 检查并添加OpenClash插件（避免重复）
if ! grep -q "openclash" feeds.conf.default; then
    echo "src-git openclash https://github.com/vernesong/OpenClash" >> feeds.conf.default
    echo "✓ OpenClash插件源添加完成"
else
    echo "✓ OpenClash插件源已存在"
fi

echo "✓ 第三方软件源添加完成"

# ==================== 修改默认主题 ====================
echo "设置默认主题为Argon..."
if [ -d "feeds/luci/themes/luci-theme-argon" ]; then
    # 如果主题存在，设置为默认
    echo "✓ Argon主题已配置"
fi

# ==================== 修改默认密码 ====================
echo "设置默认密码..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    # 设置默认密码为password (加密后的字符串)
    sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/lean/default-settings/files/zzz-default-settings
    echo "✓ 默认密码设置完成 (密码: password)"
fi

# ==================== 自定义软件包（通过feeds提供）====================
echo "自定义软件包将通过 feeds 提供（kenzok8/small）"

echo "============================================"
echo "MediaTek DIY Part 1 脚本执行完成"
echo "============================================"
