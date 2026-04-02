#!/bin/bash
# OpenWrt 构建测试和验证脚本（优化版）
# 作者: 李杰
# 功能: 测试和验证构建过程中的各个步骤
# 执行时机: 在构建过程中或构建完成后
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

# 定义测试结果变量
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# 定义测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_info "运行测试: $test_name"
    
    if eval "$test_command"; then
        log_success "测试通过: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "测试失败: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# 开始执行脚本
echo "============================================"
echo "开始执行 OpenWrt 构建测试和验证脚本 (优化版)"
echo "当前目录: $(pwd)"
echo "============================================"

# ==================== 环境检查测试 ====================
log_info "开始环境检查测试..."

run_test "检查package目录" "[ -d 'package' ]"
run_test "检查scripts目录" "[ -d 'scripts' ]"
run_test "检查Makefile文件" "[ -f 'Makefile' ]"
run_test "检查feeds.conf.default文件" "[ -f 'feeds.conf.default' ]"

# ==================== Feeds配置测试 ====================
log_info "开始Feeds配置测试..."

run_test "检查feeds配置文件存在" "[ -f 'feeds.conf.default' ]"
run_test "检查feeds配置文件非空" "[ -s 'feeds.conf.default' ]"
run_test "检查feeds配置无重复源" "! awk '{print $2}' feeds.conf.default | sort | uniq -d | grep -q ."

# 检查必要的feeds源
run_test "检查packages源" "grep -q 'packages' feeds.conf.default"
run_test "检查luci源" "grep -q 'luci' feeds.conf.default"
run_test "检查kenzo源" "grep -q 'kenzo' feeds.conf.default"
run_test "检查small源" "grep -q 'small' feeds.conf.default"

# ==================== 冲突包检查测试 ====================
log_info "开始冲突包检查测试..."

# 检查是否存在冲突包
run_test "检查无NSS包" "! find package feeds -name 'qca-nss*' -o -name 'nss-*' 2>/dev/null | grep -q ."
run_test "检查无Realtek包" "! find package feeds -name '*Realtek*' 2>/dev/null | grep -q ."
run_test "检查无fchomo包" "! find package feeds -name 'luci-app-fchomo' 2>/dev/null | grep -q ."
run_test "检查无nikki包" "! find package feeds -name 'nikki' 2>/dev/null | grep -q ."

# ==================== 配置文件测试 ====================
log_info "开始配置文件测试..."

# 检查配置文件
if [ -f ".config" ]; then
    run_test "检查.config文件存在" "true"
    run_test "检查.config文件非空" "[ -s '.config' ]"
    
    # 检查关键配置项
    run_test "检查目标平台配置" "grep -q 'CONFIG_TARGET_mediatek=y' .config"
    run_test "检查WiFi配置" "grep -q 'CONFIG_PACKAGE_kmod-mt798x-wmac=y' .config"
    run_test "检查hostapd配置" "grep -q 'CONFIG_PACKAGE_wpad-basic-openssl=y' .config"
else
    log_warning "未找到.config文件，跳过配置文件测试"
fi

# ==================== 依赖包检查测试 ====================
log_info "开始依赖包检查测试..."

# 检查必要的依赖包
run_test "检查base-files包" "[ -d 'package/base-files' ]"
run_test "检查busybox包" "[ -d 'package/utils/busybox' ]"
run_test "检查dnsmasq包" "[ -d 'package/network/services/dnsmasq' ]"
run_test "检查firewall包" "[ -d 'package/network/config/firewall' ]"

# ==================== DIY脚本测试 ====================
log_info "开始DIY脚本测试..."

# 检查DIY脚本
if [ -d "Scripts" ]; then
    run_test "检查DIY Part 1脚本" "[ -f 'Scripts/diy-part1-mediatek.sh' ]"
    run_test "检查DIY Part 2脚本" "[ -f 'Scripts/diy-part2-mediatek.sh' ]"
    run_test "检查修复脚本" "[ -f 'Scripts/fix-config-errors.sh' ]"
else
    log_warning "未找到Scripts目录，跳过DIY脚本测试"
fi

# ==================== 补丁文件测试 ====================
log_info "开始补丁文件测试..."

# 检查hostapd补丁
if [ -d "package/network/services/hostapd/patches" ]; then
    run_test "检查hostapd补丁目录" "[ -d 'package/network/services/hostapd/patches' ]"
    run_test "检查hostapd补丁文件" "[ -f 'package/network/services/hostapd/patches/0001-fix-he_mu_edca.patch' ]"
else
    log_warning "未找到hostapd补丁目录，跳过补丁文件测试"
fi

# ==================== 自定义文件测试 ====================
log_info "开始自定义文件测试..."

# 检查自定义配置文件
if [ -d "package/base-files/files" ]; then
    run_test "检查系统配置文件" "[ -f 'package/base-files/files/etc/config/system' ]"
    run_test "检查网络配置文件" "[ -f 'package/base-files/files/etc/config/network' ]"
    run_test "检查WiFi配置文件" "[ -f 'package/base-files/files/etc/config/wireless' ]"
    run_test "检查启动脚本" "[ -f 'package/base-files/files/etc/rc.local' ]"
    run_test "检查banner文件" "[ -f 'package/base-files/files/etc/banner' ]"
    run_test "检查motd文件" "[ -f 'package/base-files/files/etc/motd' ]"
else
    log_warning "未找到base-files/files目录，跳过自定义文件测试"
fi

# ==================== 编译环境测试 ====================
log_info "开始编译环境测试..."

# 检查编译工具
run_test "检查gcc编译器" "which gcc"
run_test "检查g++编译器" "which g++"
run_test "检查make工具" "which make"
run_test "检查git工具" "which git"
run_test "检查python3" "which python3"

# ==================== 磁盘空间测试 ====================
log_info "开始磁盘空间测试..."

# 检查磁盘空间
DISK_USAGE=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
DISK_AVAILABLE=$(df . | tail -1 | awk '{print $4}')

log_info "磁盘使用率: $DISK_USAGE%"
log_info "可用空间: $DISK_AVAILABLE KB"

if [ "$DISK_USAGE" -lt 90 ]; then
    run_test "检查磁盘使用率" "true"
else
    run_test "检查磁盘使用率" "false"
fi

if [ "$DISK_AVAILABLE" -gt 10485760 ]; then  # 大于10GB
    run_test "检查可用磁盘空间" "true"
else
    run_test "检查可用磁盘空间" "false"
fi

# ==================== 内存测试 ====================
log_info "开始内存测试..."

# 检查可用内存
MEMORY_AVAILABLE=$(free -m | awk '/^Mem:/{print $7}')
MEMORY_TOTAL=$(free -m | awk '/^Mem:/{print $2}')

log_info "总内存: $MEMORY_TOTAL MB"
log_info "可用内存: $MEMORY_AVAILABLE MB"

if [ "$MEMORY_TOTAL" -gt 4096 ]; then  # 大于4GB
    run_test "检查总内存" "true"
else
    run_test "检查总内存" "false"
fi

if [ "$MEMORY_AVAILABLE" -gt 2048 ]; then  # 大于2GB
    run_test "检查可用内存" "true"
else
    run_test "检查可用内存" "false"
fi

# ==================== 网络连接测试 ====================
log_info "开始网络连接测试..."

# 检查网络连接
run_test "检查网络连接" "ping -c 1 8.8.8.8 > /dev/null 2>&1"

# ==================== 构建测试 ====================
log_info "开始构建测试..."

# 测试make defconfig
if [ -f ".config" ]; then
    run_test "测试make defconfig" "make defconfig > /dev/null 2>&1"
else
    log_warning "未找到.config文件，跳过make defconfig测试"
fi

# 测试make download
run_test "测试make download" "make download -j1 > /dev/null 2>&1"

# ==================== 固件文件测试 ====================
log_info "开始固件文件测试..."

# 检查固件文件
if [ -d "bin/targets" ]; then
    FIRMWARE_COUNT=$(find bin/targets -type f \( -name "*.bin" -o -name "*.img" -o -name "*.gz" \) | wc -l)
    
    if [ "$FIRMWARE_COUNT" -gt 0 ]; then
        run_test "检查固件文件存在" "true"
        log_info "找到 $FIRMWARE_COUNT 个固件文件"
    else
        run_test "检查固件文件存在" "false"
    fi
    
    # 检查固件文件大小
    for firmware in $(find bin/targets -type f \( -name "*.bin" -o -name "*.img" -o -name "*.gz" \)); do
        FIRMWARE_SIZE=$(stat -f%z "$firmware" 2>/dev/null || stat -c%s "$firmware" 2>/dev/null)
        
        if [ "$FIRMWARE_SIZE" -gt 1048576 ]; then  # 大于1MB
            log_info "固件文件: $firmware (大小: $FIRMWARE_SIZE bytes)"
        fi
    done
else
    log_warning "未找到bin/targets目录，跳过固件文件测试"
fi

# ==================== 创建测试报告 ====================
log_info "创建测试报告..."

# 创建测试报告文件
cat > test-report.txt << EOF
OpenWrt 构建测试报告
====================
生成时间: $(date '+%Y-%m-%d %H:%M:%S')
作者: 李杰
版本: 2.0

测试摘要:
--------
总测试数: $TESTS_TOTAL
通过测试: $TESTS_PASSED
失败测试: $TESTS_FAILED
成功率: $(echo "scale=2; $TESTS_PASSED * 100 / $TESTS_TOTAL" | bc)%

测试详情:
--------
EOF

# 添加测试详情到报告
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "所有测试通过！" >> test-report.txt
else
    echo "发现 $TESTS_FAILED 个失败的测试，请检查日志。" >> test-report.txt
fi

log_success "测试报告创建完成"

# ==================== 创建验证脚本 ====================
log_info "创建验证脚本..."

cat > validate-build.sh << 'EOF'
#!/bin/bash
# 构建验证脚本
# 作者: 李杰
# 版本: 2.0

echo "开始验证构建..."

# 检查关键文件
if [ ! -f ".config" ]; then
    echo "错误: .config文件不存在"
    exit 1
fi

if [ ! -d "bin/targets" ]; then
    echo "错误: bin/targets目录不存在"
    exit 1
fi

# 检查固件文件
FIRMWARE_COUNT=$(find bin/targets -type f \( -name "*.bin" -o -name "*.img" -o -name "*.gz" \) | wc -l)
if [ "$FIRMWARE_COUNT" -eq 0 ]; then
    echo "错误: 未找到固件文件"
    exit 1
fi

echo "构建验证通过"
exit 0
EOF

chmod +x validate-build.sh
log_success "验证脚本创建完成"

# ==================== 创建快速测试脚本 ====================
log_info "创建快速测试脚本..."

cat > quick-test.sh << 'EOF'
#!/bin/bash
# 快速测试脚本
# 作者: 李杰
# 版本: 2.0

echo "开始快速测试..."

# 检查关键文件
[ -f "feeds.conf.default" ] && echo "✓ feeds配置文件存在" || echo "✗ feeds配置文件不存在"
[ -f ".config" ] && echo "✓ 配置文件存在" || echo "✗ 配置文件不存在"
[ -d "package" ] && echo "✓ package目录存在" || echo "✗ package目录不存在"
[ -d "feeds" ] && echo "✓ feeds目录存在" || echo "✗ feeds目录不存在"

# 检查冲突包
CONFLICT_COUNT=$(find package feeds -name 'qca-nss*' -o -name 'nss-*' -o -name '*Realtek*' 2>/dev/null | wc -l)
if [ "$CONFLICT_COUNT" -eq 0 ]; then
    echo "✓ 无冲突包"
else
    echo "✗ 发现 $CONFLICT_COUNT 个冲突包"
fi

echo "快速测试完成"
EOF

chmod +x quick-test.sh
log_success "快速测试脚本创建完成"

# ==================== 脚本执行完成 ====================
echo "============================================"
echo "OpenWrt 构建测试和验证脚本执行完成 (优化版)"
echo "============================================"
log_success "所有操作已成功完成"

# 显示测试结果摘要
echo ""
echo "测试结果摘要:"
echo "============================================"
echo "总测试数: $TESTS_TOTAL"
echo "通过测试: $TESTS_PASSED"
echo "失败测试: $TESTS_FAILED"
echo "成功率: $(echo "scale=2; $TESTS_PASSED * 100 / $TESTS_TOTAL" | bc)%"
echo "============================================"

# 显示可用的脚本
echo ""
echo "可用的验证脚本:"
echo "- ./validate-build.sh  # 验证构建"
echo "- ./quick-test.sh      # 快速测试"
echo ""

# 显示测试报告位置
echo "详细测试报告请查看: test-report.txt"
echo ""

# 根据测试结果给出建议
if [ "$TESTS_FAILED" -eq 0 ]; then
    log_success "所有测试通过，可以继续构建"
    exit 0
else
    log_warning "发现 $TESTS_FAILED 个失败的测试，请检查并修复"
    exit 1
fi