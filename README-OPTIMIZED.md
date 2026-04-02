# OpenWrt IPQ60XX-360V6 项目文档（优化版）

## 项目概述

本项目是一个针对CMCC RAX3000M设备的OpenWrt固件自动编译项目，基于LiBwrt的openwrt-6.x源码，集成了丰富的第三方插件和优化配置。

### 作者
- 李杰

### 版本
- 2.0 (优化版)

### 更新日期
- 2026-04-02

## 硬件规格

### CMCC RAX3000M 设备信息
- **CPU**: MediaTek MT7986A (4核 Cortex-A53 @ 1.3GHz)
- **RAM**: 512MB DDR4
- **Flash**: 128MB SPI NAND
- **网口**: 4个千兆LAN口, 1个千兆WAN口
- **WiFi**: 2.4G (MT7975) + 5G (MT7976) 双频WiFi 6
- **其他**: USB 3.0 x1, M.2 NVMe插槽

## 项目结构

```
OpenWrt-IPQ60XX-360V6/
├── .github/
│   └── workflows/
│       ├── build-mediatek.yml              # 原始构建工作流
│       └── build-mediatek-optimized.yml    # 优化版构建工作流
├── Config/
│   ├── cmcc-rax3000m.config             # 原始设备配置文件
│   └── cmcc-rax3000m-optimized.config   # 优化版设备配置文件
├── Scripts/
│   ├── diy-part1-mediatek.sh             # 原始DIY脚本 Part 1
│   ├── diy-part1-mediatek-optimized.sh   # 优化版DIY脚本 Part 1
│   ├── diy-part2-mediatek.sh             # 原始DIY脚本 Part 2
│   ├── diy-part2-mediatek-optimized.sh   # 优化版DIY脚本 Part 2
│   ├── fix-config-errors.sh               # 原始配置错误修复脚本
│   ├── fix-config-errors-optimized.sh     # 优化版配置错误修复脚本
│   ├── manage-feeds-optimized.sh         # 优化版feeds管理脚本
│   └── test-and-validate-optimized.sh    # 优化版测试和验证脚本
├── fix-patches/
│   ├── 0001-fix-compilation-issues.patch
│   ├── 0002-fix-compilation-errors.patch
│   ├── 0003-fix-hostapd-he_mu_edca.patch
│   ├── CHANGELOG-0002.md
│   └── CHANGELOG.md
├── .gitattributes
├── LICENSE
└── README.md
```

## 主要特性

### 1. 优化的构建工作流
- 简化的构建流程
- 增强的错误处理
- 详细的日志记录
- 自动化的依赖管理

### 2. 全面的配置管理
- 完整的设备配置文件
- 自定义系统配置
- 优化的网络配置
- 增强的WiFi配置

### 3. 智能的feeds管理
- 统一的feeds配置
- 自动化的feeds更新
- 冲突包清理
- 版本号修复

### 4. 强大的错误修复
- 自动化的配置修复
- hostapd编译错误修复
- 依赖冲突解决
- 配置文件生成问题修复

### 5. 全面的测试验证
- 环境检查测试
- Feeds配置测试
- 冲突包检查测试
- 配置文件测试
- 依赖包检查测试
- 编译环境测试
- 构建测试
- 固件文件测试

## 使用方法

### GitHub Actions 自动构建

1. **触发构建**
   - 手动触发：进入GitHub仓库的Actions页面，选择"Build MediaTek Firmware (Optimized)"工作流，点击"Run workflow"
   - 定时触发：每周日凌晨3点自动触发
   - 代码推送触发：推送到main分支时自动触发

2. **选择设备**
   - 在手动触发时，可以选择要编译的设备（目前只支持cmcc-rax3000m）

3. **启用SSH调试**（可选）
   - 在手动触发时，可以选择启用SSH调试功能

### 本地构建

#### 环境准备

1. **系统要求**
   - 操作系统：Ubuntu 22.04 LTS 或 Debian 11
   - 内存：至少4GB
   - 磁盘空间：至少25GB
   - 网络：稳定的网络连接

2. **安装依赖**
   ```bash
   sudo apt-get update
   sudo apt-get install -y \
     ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
     bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
     git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev \
     libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev \
     libpython3-dev libreadline-dev libssl-dev libtool lrzsz mkisofs msmtp ninja-build \
     p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools python3-setuptools \
     qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
     vim wget xmlto xxd zlib1g-dev
   ```

#### 构建步骤

1. **克隆源码**
   ```bash
   git clone https://github.com/LiBwrt/openwrt-6.x.git -b main-nss openwrt
   cd openwrt
   ```

2. **配置feeds**
   ```bash
   # 复制feeds配置文件
   cp ../Config/cmcc-rax3000m-optimized.config .config
   
   # 配置feeds源
   cat > feeds.conf.default << 'EOF'
   src-git packages https://github.com/immortalwrt/packages.git
   src-git luci https://github.com/immortalwrt/luci.git
   src-git routing https://github.com/openwrt/routing.git
   src-git telephony https://github.com/openwrt/telephony.git
   src-git kenzo https://github.com/kenzok8/openwrt-packages
   src-git small https://github.com/kenzok8/small
   src-git fantastic_packages https://github.com/fantastic-packages/packages.git;master
   EOF
   ```

3. **更新并安装feeds**
   ```bash
   ./scripts/feeds update -a
   ./scripts/feeds install -a
   ```

4. **执行DIY脚本**
   ```bash
   # 执行DIY脚本 Part 1
   chmod +x ../Scripts/diy-part1-mediatek-optimized.sh
   ../Scripts/diy-part1-mediatek-optimized.sh
   
   # 执行DIY脚本 Part 2
   chmod +x ../Scripts/diy-part2-mediatek-optimized.sh
   ../Scripts/diy-part2-mediatek-optimized.sh
   ```

5. **执行配置错误修复脚本**
   ```bash
   chmod +x ../Scripts/fix-config-errors-optimized.sh
   ../Scripts/fix-config-errors-optimized.sh
   ```

6. **加载设备配置**
   ```bash
   cp ../Config/cmcc-rax3000m-optimized.config .config
   make defconfig
   ```

7. **下载依赖包**
   ```bash
   make download -j8
   ```

8. **开始编译**
   ```bash
   make -j$(nproc)
   ```

9. **查找固件**
   ```bash
   find bin/targets/ -type f \( -name "*.bin" -o -name "*.img" -o -name "*.gz" \)
   ```

## 脚本说明

### 1. DIY脚本 Part 1 (diy-part1-mediatek-optimized.sh)

**功能**: 在更新feeds之前执行的自定义操作

**主要操作**:
- 修改默认IP地址为192.168.100.1
- 修改默认主机名为OpenWrt-AutoBuild
- 修改默认时区为CST-8 (Asia/Shanghai)
- 修改默认密码为password
- 处理NSS驱动问题
- 添加第三方软件源
- 清理冲突包
- 修复luci-theme-design版本号格式问题
- 创建自定义配置文件
- 创建自定义启动脚本
- 创建自定义banner
- 创建自定义motd
- 创建自定义软件源配置
- 创建系统优化配置
- 创建定时任务

**执行时机**: feeds更新之前

### 2. DIY脚本 Part 2 (diy-part2-mediatek-optimized.sh)

**功能**: 在更新feeds之后执行的自定义操作

**主要操作**:
- 修改默认主题为Argon
- 修改默认语言为中文
- 修改默认时区
- 修改默认主机名
- 配置默认WiFi
- 修改网络配置，添加IPv6支持
- 添加自定义防火墙规则，支持IPv6
- 修复hostapd编译错误
- 处理依赖缺失问题
- 修复luci-theme-design版本号格式问题
- 安装缺失的依赖
- 创建自定义网络优化脚本
- 创建自定义系统监控脚本
- 创建自定义系统清理脚本

**执行时机**: feeds更新和安装完成后

### 3. 配置错误修复脚本 (fix-config-errors-optimized.sh)

**功能**: 修复配置文件和依赖问题

**主要操作**:
- 清理临时文件
- 清理冲突的feeds源
- 清理可能导致配置文件错误的包
- 处理mac80211中的NSS依赖
- 修复hostapd编译错误
- 修复luci-theme-design版本号格式问题
- 修复feeds配置
- 处理内核模块依赖问题
- 修复配置文件生成问题
- 创建配置验证脚本
- 创建清理脚本
- 创建构建准备脚本

**执行时机**: 在执行make defconfig之前

### 4. Feeds管理脚本 (manage-feeds-optimized.sh)

**功能**: 统一管理feeds配置

**主要操作**:
- 定义feeds源配置
- 备份原始feeds配置
- 创建新的feeds配置
- 验证feeds配置
- 清理旧的feeds目录
- 更新feeds
- 安装feeds
- 验证feeds安装
- 清理冲突包
- 修复版本号问题
- 创建feeds状态报告
- 创建feeds更新脚本
- 创建feeds清理脚本
- 创建feeds验证脚本

**执行时机**: 在执行feeds更新之前

### 5. 测试和验证脚本 (test-and-validate-optimized.sh)

**功能**: 测试和验证构建过程中的各个步骤

**主要测试**:
- 环境检查测试
- Feeds配置测试
- 冲突包检查测试
- 配置文件测试
- 依赖包检查测试
- DIY脚本测试
- 补丁文件测试
- 自定义文件测试
- 编译环境测试
- 磁盘空间测试
- 内存测试
- 网络连接测试
- 构建测试
- 固件文件测试

**执行时机**: 在构建过程中或构建完成后

## 配置文件说明

### 设备配置文件 (cmcc-rax3000m-optimized.config)

**功能**: 定义设备的编译配置

**主要配置项**:
- 目标平台配置
- 固件版本信息
- 编译优化参数
- 基本系统组件
- 网络基础功能
- IPv6支持
- WiFi配置
- USB支持
- 文件系统支持
- 声音支持
- 网络驱动支持
- 系统工具
- LuCI主题
- 网络插件
- 存储管理
- 代理插件
- 网络工具
- 系统管理
- 常用工具
- Python支持
- Go语言支持
- Node.js支持
- 编译选项

## 默认配置

### 网络配置
- **默认IP**: 192.168.100.1
- **默认网关**: 自动获取
- **DNS服务器**: 223.5.5.5, 119.29.29.29
- **IPv6支持**: 已启用

### WiFi配置
- **2.4G SSID**: OpenWrt-2.4G
- **5G SSID**: OpenWrt-5G
- **WiFi密码**: 12345678
- **加密方式**: PSK2

### 系统配置
- **主机名**: OpenWrt-AutoBuild
- **时区**: CST-8 (Asia/Shanghai)
- **语言**: 中文
- **默认密码**: password

### 软件源
- **官方源**: 清华大学镜像
- **第三方源**: kenzok8, fantastic-packages

## 常见问题

### 1. 编译失败

**问题**: 编译过程中出现错误

**解决方案**:
1. 检查依赖是否完整安装
2. 运行配置错误修复脚本
3. 清理临时文件后重新编译
4. 查看详细的编译日志

### 2. Feeds更新失败

**问题**: feeds更新或安装失败

**解决方案**:
1. 检查网络连接
2. 清理旧的feeds目录
3. 重新运行feeds管理脚本
4. 检查feeds配置是否正确

### 3. 配置文件错误

**问题**: make defconfig时出现配置文件错误

**解决方案**:
1. 运行配置错误修复脚本
2. 检查配置文件格式
3. 清理临时文件
4. 重新生成配置文件

### 4. hostapd编译错误

**问题**: hostapd编译时出现he_mu_edca错误

**解决方案**:
1. 确保hostapd补丁已应用
2. 检查CONFIG_IEEE80211AX配置
3. 重新运行配置错误修复脚本

### 5. 依赖冲突

**问题**: 出现包依赖冲突

**解决方案**:
1. 运行配置错误修复脚本
2. 清理冲突包
3. 重新安装feeds
4. 检查配置文件

## 最佳实践

### 1. 定期更新
- 定期更新源码和feeds
- 及时更新配置文件
- 关注上游项目的更新

### 2. 备份重要文件
- 备份配置文件
- 备份自定义脚本
- 备份feeds配置

### 3. 测试验证
- 在编译前运行测试脚本
- 验证配置文件的正确性
- 检查依赖的完整性

### 4. 错误处理
- 及时处理编译错误
- 记录错误日志
- 分析错误原因

### 5. 性能优化
- 使用多线程编译
- 优化编译参数
- 合理配置系统资源

## 技术支持

### 源码仓库
- [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x)
- [kenzok8/openwrt-packages](https://github.com/kenzok8/openwrt-packages)
- [kenzok8/small](https://github.com/kenzok8/small)
- [fantastic-packages/packages](https://github.com/fantastic-packages/packages)

### 社区资源
- OpenWrt官方文档: https://openwrt.org/
- OpenWrt论坛: https://forum.openwrt.org/
- ImmortalWrt: https://github.com/immortalwrt

## 更新日志

### 版本 2.0 (2026-04-02)
- 重新设计构建工作流程
- 重构设备配置文件
- 优化DIY脚本
- 重写配置错误修复脚本
- 优化feeds配置和管理
- 添加测试和验证步骤
- 优化文档和注释

### 版本 1.0 (初始版本)
- 基础构建功能
- 基本配置管理
- 简单的DIY脚本

## 许可证

本项目采用GPL-2.0许可证。

## 贡献

欢迎提交问题和拉取请求。

## 免责声明

本固件为自动编译生成，仅供测试使用。刷机有风险，请谨慎操作。使用本固件所造成的任何损失，作者不承担责任。

## 联系方式

- 作者: 李杰
- GitHub: https://github.com/wwz09

---

**注意**: 本项目仅供学习和研究使用，请勿用于非法用途。