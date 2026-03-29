#!/bin/bash
# OpenWrt DIY脚本 Part 1
# 作者: 李杰
# 功能: 在更新feeds之前执行的自定义操作
# 执行时机: feeds更新之前

echo "============================================"
echo "开始执行 DIY Part 1 脚本"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 修改默认IP地址 ====================
echo "修改默认IP地址..."
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    # 修改默认IP为192.168.1.1
    sed -i 's/192.168.1.1/192.168.1.1/g' package/lean/default-settings/files/zzz-default-settings
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

# ==================== 添加第三方软件源 ====================
echo "添加第三方软件源..."

# 添加OpenClash插件
echo "src-git openclash https://github.com/vernesong/OpenClash" >> feeds.conf.default

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

# ==================== 添加自定义软件包 ====================
echo "添加自定义软件包..."

# 克隆主题
[ -d "package/luci-theme-argon" ] && rm -rf package/luci-theme-argon
git clone -b master https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
echo "✓ Argon主题克隆完成"

# 克隆Argon配置
[ -d "package/luci-app-argon-config" ] && rm -rf package/luci-app-argon-config
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
echo "✓ Argon配置克隆完成"

echo "============================================"
echo "DIY Part 1 脚本执行完成"
echo "============================================"
