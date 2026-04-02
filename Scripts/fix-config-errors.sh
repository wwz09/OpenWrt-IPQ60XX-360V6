#!/bin/bash
# OpenWrt 配置错误修复脚本
# 作者: 李杰
# 功能: 修复 tmp/.config-package.in 文件的语法错误
# 执行时机: 在执行 make defconfig 之前

echo "============================================"
echo "开始执行 OpenWrt 配置错误修复脚本"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 清理冲突的 feeds 源 ====================
echo "清理冲突的 feeds 源..."

# 备份原始 feeds 配置
if [ -f "feeds.conf.default" ]; then
    cp feeds.conf.default feeds.conf.default.bak
    echo "✓ 已备份原始 feeds 配置"
    
    # 清理重复的 feeds 源
    echo "清理重复的 feeds 源..."
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    echo "✓ 已清理重复的 feeds 源"
    
    # 显示清理后的 feeds 配置
    echo "清理后的 feeds 配置:"
    cat feeds.conf.default
fi

# ==================== 清理可能导致配置文件错误的包 ====================
echo "清理可能导致配置文件错误的包..."

# 清理可能导致冲突的包
find package -name "qca-nss*" -type d | xargs rm -rf 2>/dev/null
find package -name "nss-*" -type d | xargs rm -rf 2>/dev/null
find package -name "luci-app-fchomo" -type d | xargs rm -rf 2>/dev/null
find package -name "nikki" -type d | xargs rm -rf 2>/dev/null
find package -name "fwupd*" -type d | xargs rm -rf 2>/dev/null
find package -name "onionshare-cli" -type d | xargs rm -rf 2>/dev/null
find package -name "fail2ban" -type d | xargs rm -rf 2>/dev/null
find package -name "setools" -type d | xargs rm -rf 2>/dev/null
find package -name "trojan-plus" -type d | xargs rm -rf 2>/dev/null

# 清理 feeds 中的冲突包
find feeds -name "qca-nss*" -type d | xargs rm -rf 2>/dev/null
find feeds -name "nss-*" -type d | xargs rm -rf 2>/dev/null
find feeds -name "luci-app-fchomo" -type d | xargs rm -rf 2>/dev/null
find feeds -name "nikki" -type d | xargs rm -rf 2>/dev/null
find feeds -name "fwupd*" -type d | xargs rm -rf 2>/dev/null
find feeds -name "onionshare-cli" -type d | xargs rm -rf 2>/dev/null

# 清理可能导致配置文件生成错误的包
find package -name "*Realtek*" -type d | xargs rm -rf 2>/dev/null
find feeds -name "*Realtek*" -type d | xargs rm -rf 2>/dev/null

# 清理可能导致依赖冲突的包
find package -name "luci-app-oaf" -type d | xargs rm -rf 2>/dev/null
find package -name "luci-app-control-timewol" -type d | xargs rm -rf 2>/dev/null
find package -name "luci-app-cpufreq" -type d | xargs rm -rf 2>/dev/null

# 清理sqm-scripts-nss，避免与普通sqm-scripts冲突
find package -name "sqm-scripts-nss" -type d | xargs rm -rf 2>/dev/null
find feeds -name "sqm-scripts-nss" -type d | xargs rm -rf 2>/dev/null

echo "✓ 已清理冲突包"

# ==================== 修复hostapd编译错误 ====================
echo "修复hostapd编译错误..."

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

echo "✓ hostapd补丁创建完成"

# ==================== 清理临时文件 ====================
echo "清理临时文件..."

# 清理可能导致问题的临时文件
rm -rf tmp/* 2>/dev/null
rm -rf build_dir/* 2>/dev/null
rm -rf staging_dir/* 2>/dev/null
rm -f .config 2>/dev/null
rm -f .config.old 2>/dev/null

# 清理可能的配置文件缓存
find . -name "*.in" -type f -exec rm -f {} \; 2>/dev/null

# 清理可能的包缓存
find . -name "*.ipk" -type f -exec rm -f {} \; 2>/dev/null

echo "✓ 临时文件清理完成"

# ==================== 修复feeds配置 ====================
echo "修复feeds配置..."

# 确保feeds配置正确
if [ -f "feeds.conf.default" ]; then
    # 移除可能导致冲突的feeds
    grep -v "qca-nss" feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    grep -v "nss-" feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    
    # 确保只包含必要的feeds
    if ! grep -q "kenzo" feeds.conf.default; then
        echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> feeds.conf.default
    fi
    
    if ! grep -q "small" feeds.conf.default; then
        echo "src-git small https://github.com/kenzok8/small" >> feeds.conf.default
    fi
    
    if ! grep -q "fantastic_packages" feeds.conf.default; then
        echo "src-git fantastic_packages https://github.com/fantastic-packages/packages.git;master" >> feeds.conf.default
    fi
    
    # 再次清理重复
    awk '!seen[$0]++' feeds.conf.default > feeds.conf.default.tmp && mv feeds.conf.default.tmp feeds.conf.default
    
    echo "✓ feeds配置修复完成"
    echo "修复后的feeds配置:"
    cat feeds.conf.default
fi

# ==================== 修复配置文件生成问题 ====================
echo "修复配置文件生成问题..."

# 创建一个修复脚本来处理.config-package.in生成问题
echo "创建配置文件生成修复脚本..."

cat > fix-config-package.sh << 'EOF'
#!/bin/bash
# 修复.config-package.in生成问题

# 清理可能导致问题的包信息
find . -name "*.mk" -type f -exec grep -l "Realtek" {} \; | xargs rm -f 2>/dev/null
find . -name "*.in" -type f -exec grep -l "Realtek" {} \; | xargs rm -f 2>/dev/null

# 清理可能导致问题的配置文件
rm -f tmp/.config-package.in 2>/dev/null
rm -f tmp/.config 2>/dev/null

# 重新生成feeds
echo "重新生成feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

echo "配置文件生成修复完成"
EOF

chmod +x fix-config-package.sh

# 执行配置文件生成修复脚本
if [ -f "fix-config-package.sh" ]; then
    ./fix-config-package.sh
    rm -f fix-config-package.sh
fi

echo "✓ 配置文件生成问题修复完成"

echo "============================================"
echo "OpenWrt 配置错误修复脚本执行完成"
echo "============================================"
echo ""
echo "修复完成，现在可以执行以下命令继续构建:"
echo "1. ./scripts/feeds update -a"
echo "2. ./scripts/feeds install -a"
echo "3. make defconfig"
echo "4. make download -j8"
echo "5. make -j$(nproc)"
echo ""
