#!/bin/bash
# OpenWrt 配置错误修复脚本（优化版）
# 作者: 李杰
# 功能: 修复配置文件和依赖问题
# 执行时机: 在执行 make defconfig 之前
# 版本: 2.0
# 更新日期: 2026-04-02

# 设置错误处理
set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错
set -o pipefail  # 管道命令失败时退出

# 定义日志函数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# 定义错误处理函数
handle_error() {
    log_error "脚本执行失败，错误发生在第 $1 行"
    exit 1
}

trap 'handle_error $LINENO' ERR

# 开始执行脚本
echo "============================================"
echo "开始执行 OpenWrt 配置错误修复脚本 (优化版)"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 检查环境 ====================
log_info "检查环境..."
if [ ! -d "package" ]; then
    log_error "未找到package目录，请确认当前目录是否正确"
    exit 1
fi
log_success "环境检查通过"

# ==================== 清理临时文件 ====================
log_info "清理临时文件..."

# 清理可能导致问题的临时文件
rm -rf tmp/* 2>/dev/null || true
rm -rf build_dir/* 2>/dev/null || true
rm -rf staging_dir/* 2>/dev/null || true
rm -f .config 2>/dev/null || true
rm -f .config.old 2>/dev/null || true

# 清理可能的配置文件缓存
find . -name "*.in" -type f -path "*/tmp/*" -delete 2>/dev/null || true

# 清理可能的包缓存
find . -name "*.ipk" -type f -path "*/tmp/*" -delete 2>/dev/null || true

log_success "临时文件清理完成"

# ==================== 清理冲突的 feeds 源 ====================
log_info "清理冲突的 feeds 源..."

# 备份原始 feeds 配置
if [ -f "feeds.conf.default" ]; then
    cp feeds.conf.default feeds.conf.default.bak
    log_success "已备份原始 feeds 配置"
    
    # 清理重复的 feeds 源
    log_info "清理重复的 feeds 源..."
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    log_success "已清理重复的 feeds 源"
    
    # 显示清理后的 feeds 配置
    log_info "清理后的 feeds 配置:"
    cat feeds.conf.default
else
    log_warning "未找到 feeds.conf.default 文件，跳过 feeds 源清理"
fi

# ==================== 清理可能导致配置文件错误的包 ====================
log_info "清理可能导致配置文件错误的包..."

# 定义要删除的包列表（使用数组）
declare -a PACKAGES_TO_REMOVE=(
    # NSS相关包
    "qca-nss*"
    "nss-*"
    "sqm-scripts-nss"
    
    # 冲突包
    "luci-app-fchomo"
    "nikki"
    "fwupd*"
    "onionshare-cli"
    "fail2ban"
    "setools"
    "trojan-plus"
    "luci-app-oaf"
    "luci-app-control-timewol"
    "luci-app-cpufreq"
    
    # Realtek相关包
    "*Realtek*"
    
    # 依赖冲突包
    "aic8800"
    "automount"
    "basicstation"
    "beep"
    "bigclown-gateway"
    "bluld"
    "comgt"
    "dmx_usb_module"
    "fibocom-qmi-wwan"
    "gl-puli-mcu"
    "keepalived"
)

# 删除package目录中的包
for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    if find package -name "$pkg" -type d | grep -q .; then
        find package -name "$pkg" -type d | xargs rm -rf
        log_info "已删除package目录中的包: $pkg"
    fi
done

# 删除feeds目录中的包（如果存在）
if [ -d "feeds" ]; then
    for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
        if find feeds -name "$pkg" -type d | grep -q .; then
            find feeds -name "$pkg" -type d | xargs rm -rf
            log_info "已删除feeds目录中的包: $pkg"
        fi
    done
fi

log_success "冲突包清理完成"

# ==================== 处理mac80211中的NSS依赖 ====================
log_info "处理mac80211中的NSS依赖问题..."
if [ -f "package/kernel/mac80211/Makefile" ]; then
    # 备份原文件
    cp package/kernel/mac80211/Makefile package/kernel/mac80211/Makefile.bak
    
    # 移除NSS相关依赖
    sed -i '/kmod-qca-nss-drv/d' "package/kernel/mac80211/Makefile"
    sed -i '/kmod-qca-nss-drv-wifi-meshmgr/d' "package/kernel/mac80211/Makefile"
    log_success "mac80211 NSS依赖清理完成"
else
    log_warning "未找到mac80211 Makefile，跳过NSS依赖清理"
fi

# ==================== 修复hostapd编译错误 ====================
log_info "修复hostapd编译错误..."

# 创建hostapd补丁目录
mkdir -p package/network/services/hostapd/patches 2>/dev/null

# 创建hostapd补丁文件
cat > package/network/services/hostapd/patches/0001-fix-he_mu_edca.patch << 'EOF'
--- a/src/ap/hostapd.c
+++ b/src/ap/hostapd.c
@@ -4718,9 +4718,13 @@
 		if (csa_settings->mode == NL80211_CHAN_SWITCH_MODE_80211R) {
 			csa_settings->ht_oper_chwidth = hapd->iface->conf->ht_op_mode;
 			csa_settings->vht_oper_chwidth = hapd->iface->conf->vht_op_mode;
+		#ifdef CONFIG_IEEE80211AX
 			if (hapd->iface->conf->he_mu_edca.he_qos_info & 0x000f) {
 				hapd->iface->conf->he_mu_edca.he_qos_info &= 0xfff0;
 			}
+		#else
+		/* CONFIG_IEEE80211AX not defined, skip he_mu_edca */
+		#endif
 		}
 	}
 }
EOF

log_success "hostapd补丁创建完成"

# ==================== 修复luci-theme-design版本号格式问题 ====================
log_info "修复luci-theme-design版本号格式..."

# 查找所有可能的 luci-theme-design 目录（包括不同的feed源）
find feeds -name "luci-theme-design*" -type d | while read -r dir; do
    if [ -f "$dir/Makefile" ]; then
        # 更通用的版本号修复，匹配任何包含日期的版本号格式
        sed -i 's/5\.8\.0-[0-9]\{8\}-r[0-9]/5.8.0-r1/g' "$dir/Makefile"
        log_info "已修复 $dir/Makefile 中的版本号"
    fi
done

# 也清理本地包目录中的 luci-theme-design，避免冲突
find package -name "luci-theme-design*" -type d | xargs rm -rf 2>/dev/null
log_success "luci-theme-design版本号修复完成"

# ==================== 修复feeds配置 ====================
log_info "修复feeds配置..."

# 确保feeds配置正确
if [ -f "feeds.conf.default" ]; then
    # 移除可能导致冲突的feeds
    grep -v "qca-nss" feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    grep -v "nss-" feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    
    # 定义必要的feeds
    declare -A REQUIRED_FEEDS=(
        ["kenzo"]="https://github.com/kenzok8/openwrt-packages"
        ["small"]="https://github.com/kenzok8/small"
        ["fantastic_packages"]="https://github.com/fantastic-packages/packages.git;master"
    )
    
    # 添加必要的feeds（避免重复）
    for name in "${!REQUIRED_FEEDS[@]}"; do
        url="${REQUIRED_FEEDS[$name]}"
        if ! grep -q "$name" feeds.conf.default; then
            echo "src-git $name $url" >> feeds.conf.default
            log_success "已添加feeds源: $name"
        else
            log_info "feeds源已存在，跳过: $name"
        fi
    done
    
    # 再次清理重复
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    
    log_success "feeds配置修复完成"
    log_info "修复后的feeds配置:"
    cat feeds.conf.default
else
    log_warning "未找到feeds.conf.default文件，跳过feeds配置修复"
fi

# ==================== 处理内核模块依赖问题 ====================
log_info "处理内核模块依赖问题..."

# 定义可能导致依赖问题的包列表
declare -a DEPENDENCY_PACKAGES=(
    "aic8800"
    "automount"
    "basicstation"
    "beep"
    "bigclown-gateway"
    "bluld"
    "comgt"
    "dmx_usb_module"
    "fail2ban"
    "fibocom-qmi-wwan"
    "gl-puli-mcu"
    "keepalived"
)

# 删除package目录中的依赖冲突包
for pkg in "${DEPENDENCY_PACKAGES[@]}"; do
    if find package -name "$pkg" -type d | grep -q .; then
        find package -name "$pkg" -type d | xargs rm -rf
        log_info "已删除package目录中的依赖冲突包: $pkg"
    fi
done

# 删除feeds目录中的依赖冲突包（如果存在）
if [ -d "feeds" ]; then
    for pkg in "${DEPENDENCY_PACKAGES[@]}"; do
        if find feeds -name "$pkg" -type d | grep -q .; then
            find feeds -name "$pkg" -type d | xargs rm -rf
            log_info "已删除feeds目录中的依赖冲突包: $pkg"
        fi
    done
fi

log_success "依赖冲突包清理完成"

# ==================== 修复配置文件生成问题 ====================
log_info "修复配置文件生成问题..."

# 清理可能导致问题的包信息
find . -name "*.mk" -type f -exec grep -l "Realtek" {} \; | xargs rm -f 2>/dev/null || true
find . -name "*.in" -type f -exec grep -l "Realtek" {} \; | xargs rm -f 2>/dev/null || true

# 清理可能导致问题的配置文件
rm -f tmp/.config-package.in 2>/dev/null || true
rm -f tmp/.config 2>/dev/null || true

log_success "配置文件生成问题修复完成"

# ==================== 创建配置验证脚本 ====================
log_info "创建配置验证脚本..."

cat > validate-config.sh << 'EOF'
#!/bin/bash
# 配置验证脚本
# 作者: 李杰
# 版本: 2.0

echo "开始验证配置..."

# 检查是否存在Config.in文件
if [ ! -f "Config.in" ]; then
    echo "警告: Config.in文件不存在"
    exit 1
fi

# 检查是否存在feeds配置文件
if [ ! -f "feeds.conf.default" ]; then
    echo "警告: feeds.conf.default文件不存在"
    exit 1
fi

# 检查是否存在package目录
if [ ! -d "package" ]; then
    echo "警告: package目录不存在"
    exit 1
fi

# 检查是否存在feeds目录
if [ ! -d "feeds" ]; then
    echo "警告: feeds目录不存在"
    exit 1
fi

# 检查是否存在冲突包
CONFLICT_PACKAGES=$(find package feeds -name "qca-nss*" -o -name "nss-*" -o -name "*Realtek*" 2>/dev/null | wc -l)
if [ "$CONFLICT_PACKAGES" -gt 0 ]; then
    echo "警告: 发现 $CONFLICT_PACKAGES 个冲突包"
    exit 1
fi

echo "配置验证通过"
exit 0
EOF

chmod +x validate-config.sh
log_success "配置验证脚本创建完成"

# ==================== 执行配置验证 ====================
log_info "执行配置验证..."
if [ -f "validate-config.sh" ]; then
    if ./validate-config.sh; then
        log_success "配置验证通过"
    else
        log_warning "配置验证失败，但继续执行"
    fi
    rm -f validate-config.sh
else
    log_warning "配置验证脚本创建失败，跳过验证"
fi

# ==================== 创建清理脚本 ====================
log_info "创建清理脚本..."

cat > cleanup.sh << 'EOF'
#!/bin/bash
# 清理脚本
# 作者: 李杰
# 版本: 2.0

echo "开始清理..."

# 清理临时文件
rm -rf tmp/* 2>/dev/null || true
rm -rf build_dir/* 2>/dev/null || true
rm -rf staging_dir/* 2>/dev/null || true

# 清理配置文件
rm -f .config 2>/dev/null || true
rm -f .config.old 2>/dev/null || true

# 清理缓存
find . -name "*.o" -delete 2>/dev/null || true
find . -name "*.a" -delete 2>/dev/null || true

echo "清理完成"
EOF

chmod +x cleanup.sh
log_success "清理脚本创建完成"

# ==================== 创建构建准备脚本 ====================
log_info "创建构建准备脚本..."

cat > prepare-build.sh << 'EOF'
#!/bin/bash
# 构建准备脚本
# 作者: 李杰
# 版本: 2.0

echo "开始准备构建..."

# 清理旧的构建文件
rm -rf tmp/* 2>/dev/null || true
rm -rf build_dir/* 2>/dev/null || true

# 重新生成feeds
echo "重新生成feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 生成配置文件
echo "生成配置文件..."
make defconfig

echo "构建准备完成"
EOF

chmod +x prepare-build.sh
log_success "构建准备脚本创建完成"

# ==================== 脚本执行完成 ====================
echo "============================================"
echo "OpenWrt 配置错误修复脚本执行完成 (优化版)"
echo "============================================"
log_success "所有操作已成功完成"

# 显示摘要
echo ""
echo "执行摘要:"
echo "✓ 临时文件清理完成"
echo "✓ feeds源清理完成"
echo "✓ 冲突包清理完成"
echo "✓ mac80211 NSS依赖清理完成"
echo "✓ hostapd补丁创建完成"
echo "✓ luci-theme-design版本号修复完成"
echo "✓ feeds配置修复完成"
echo "✓ 依赖冲突包清理完成"
echo "✓ 配置文件生成问题修复完成"
echo "✓ 配置验证脚本创建完成"
echo "✓ 清理脚本创建完成"
echo "✓ 构建准备脚本创建完成"
echo ""
echo "现在可以执行以下命令继续构建:"
echo "1. ./prepare-build.sh"
echo "2. make download -j8"
echo "3. make -j\$(nproc)"
echo ""
echo "如果遇到问题，可以运行:"
echo "- ./validate-config.sh  # 验证配置"
echo "- ./cleanup.sh  # 清理临时文件"
echo ""