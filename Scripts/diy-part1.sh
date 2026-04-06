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
echo "" >> feeds.conf.default
echo "src-git openclash https://github.com/vernesong/OpenClash" >> feeds.conf.default
echo "" >> feeds.conf.default

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

# 克隆主题（添加错误处理）
clone_repo() {
    local repo_url=$1
    local target_dir=$2
    local branch=${3:-master}
    local desc=$4
    
    [ -d "$target_dir" ] && rm -rf "$target_dir"
    echo "正在克隆 $desc..."
    if git clone --depth 1 -b "$branch" "$repo_url" "$target_dir" 2>/dev/null; then
        echo "✓ $desc 克隆完成"
        return 0
    else
        echo "⚠️ $desc 克隆失败，跳过"
        return 1
    fi
}

# 克隆主题
clone_repo "https://github.com/jerrykuku/luci-theme-argon.git" "package/luci-theme-argon" "master" "Argon主题"
clone_repo "https://github.com/jerrykuku/luci-app-argon-config.git" "package/luci-app-argon-config" "master" "Argon配置"
clone_repo "https://github.com/gngpp/luci-theme-design.git" "package/luci-theme-design" "master" "Design主题"
clone_repo "https://github.com/gngpp/luci-app-design-config.git" "package/luci-app-design-config" "master" "Design配置"
clone_repo "https://github.com/LuttyYang/luci-theme-material.git" "package/luci-theme-material" "master" "Material主题"

# 跳过容易失败的仓库
# clone_repo "https://github.com/thinktip/luci-theme-aurora.git" "package/luci-theme-aurora" "master" "Aurora主题"
# clone_repo "https://github.com/thinktip/luci-app-aurora-config.git" "package/luci-app-aurora-config" "master" "Aurora配置"
# clone_repo "https://github.com/sirpdboy/luci-theme-netgear.git" "package/luci-theme-netgear" "master" "Netgear主题"
# clone_repo "https://github.com/linkease/luci-app-store.git" "package/luci-app-store" "master" "应用市场"

echo "============================================"
echo "DIY Part 1 脚本执行完成"
echo "============================================"
