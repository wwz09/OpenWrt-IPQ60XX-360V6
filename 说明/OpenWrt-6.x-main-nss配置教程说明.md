# OpenWrt 6.x main-nss 配置教程说明

## 1. 源码概述

OpenWrt 6.x main-nss 是一个基于 OpenWrt 官方源码，集成了 NSS（Network SubSystem）加速功能的固件版本，专为 Qualcomm IPQ 系列设备优化。NSS 加速可以显著提升网络性能，特别是在处理高带宽流量时。

## 2. 支持的设备

### 2.1 IPQ50XX 系列

- **ipq5018-ax6000**
- **ipq5018-ax830**
- **ipq5018-ax850**
- **ipq5018-gl-b3000** (GL.iNet B3000)
- **ipq5018-mr3000d-ci**
- **ipq5018-mr5500**
- **ipq5018-mx2000**
- **ipq5018-mx5500**
- **ipq5018-mx6200**
- **ipq5018-pz-l8**
- **ipq5018-scr50axe**
- **ipq5018-spnmx56**

### 2.2 IPQ60XX 系列

- **ipq6000-360v6** (360V6)
- **ipq6000-ap120c-ax**
- **ipq6000-ax18**
- **ipq6000-ax1800** (小米 AX1800)
- **ipq6000-ax5-jdcloud** (京东云 AX5)
- **ipq6000-ax5**
- **ipq6000-gl-ax1800** (GL.iNet AX1800)
- **ipq6000-gl-axt1800** (GL.iNet AXT1800)
- **ipq6000-m2** (ZN M2)
- **ipq6000-mr7350**
- **ipq6000-nn6000-v1** (Link NN6000-v1)
- **ipq6000-nn6000-v2** (Link NN6000-v2)
- **ipq6000-re-ss-01** (京东云 re-ss-01)
- **ipq6010-e1**
- **ipq6010-mango-dvk**
- **ipq6010-re-cs-02**
- **ipq6010-re-cs-07**
- **ipq6010-wax214**
- **ipq6010-wax610**
- **ipq6010-wax610y**
- **ipq6010-xe3-4**
- **ipq6018-fap650**
- **ipq6018-mr7500**
- **ipq6018-rbr350**
- **ipq6018-rbs350**

### 2.3 IPQ807X 系列

- **ipq8070-cax1800**
- **ipq8070-nwa110ax**
- **ipq8070-rm2-6**
- **ipq8071-ap8220**
- **ipq8071-ax3600**
- **ipq8071-ax6**
- **ipq8071-eap102**
- **ipq8071-mf269**
- **ipq8071-nwa210ax**
- **ipq8072-301w**
- **ipq8072-aw1000**
- **ipq8072-ax880**
- **ipq8072-ax9000**
- **ipq8072-cr1000a**
- **ipq8072-dl-wrx36**
- **ipq8072-eap620hd-v1**
- **ipq8072-eap660hd-v1**
- **ipq8072-fg2000**
- **ipq8072-haze**
- **ipq8072-mx5300**
- **ipq8072-mx8500**
- **ipq8072-sax1v1k**
- **ipq8072-wax218**
- **ipq8072-wax620**
- **ipq8072-wpq873**
- **ipq8072-zbt-z800ax**
- **ipq8074-deco-x80-5g**
- **ipq8074-nbg7815**
- **ipq8074-rax120v2**
- **ipq8074-rbr750**
- **ipq8074-rbs750**
- **ipq8074-rt-ax89x**
- **ipq8074-wax630**
- **ipq8174-homewrk**
- **ipq8174-mx4200v1**
- **ipq8174-mx4200v2**
- **ipq8174-mx4300**

### 2.4 IPQ95XX 系列

- **ipq9570-kiwi-dvk**

## 3. 环境准备

### 3.1 系统要求

- **操作系统**：Ubuntu 22.04 LTS 或 Debian 11
- **内存**：至少 4GB
- **磁盘空间**：至少 25GB 可用空间
- **CPU**：至少 2 核心

### 3.2 安装依赖

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libfuse-dev libssl-dev libtool lrzsz \
genisoimage msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip libpython3-dev qemu-utils \
rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
```

## 4. 源码获取

### 4.1 克隆源码

```bash
git clone --depth 1 --single-branch -b main-nss https://github.com/LiBwrt/openwrt-6.x.git openwrt
cd openwrt
```

### 4.2 更新 feeds

```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

## 5. 配置编译

### 5.1 进入配置界面

```bash
make menuconfig
```

### 5.2 基本配置

1. **选择目标平台**：
   - `Target System` → `Qualcomm Atheros IPQ (ipq)`
   - `Subtarget` → 根据设备选择对应的子目标（如 `ipq60xx`）
   - `Target Profile` → 选择具体的设备型号

2. **NSS 配置**：
   - `Kernel modules` → `Network Devices` → 确保启用 `kmod-ath11k` 相关模块
   - `Kernel modules` → `Network Support` → 确保启用 `kmod-qca-nss-dp` 等 NSS 相关模块

3. **软件包配置**：
   - `LuCI` → 选择需要的 Web 界面组件
   - `Network` → 选择网络相关组件
   - `Utilities` → 选择实用工具

### 5.3 配置文件的配置方法

#### 5.3.1 使用默认配置文件

OpenWrt 源码中已经为各个设备提供了默认的配置文件，位于 `target/linux/qualcommax/<子目标>/config-default` 文件中。这些配置文件包含了设备的基本配置信息。

#### 5.3.2 自定义配置文件

1. **复制默认配置文件**：
   ```bash
   cp target/linux/qualcommax/ipq60xx/config-default .config
   ```

2. **修改配置文件**：
   - 使用文本编辑器修改 `.config` 文件，添加或删除需要的配置选项
   - 例如，添加 luci 界面：
     ```bash
     echo "CONFIG_PACKAGE_luci=y" >> .config
     echo "CONFIG_PACKAGE_luci-base=y" >> .config
     echo "CONFIG_PACKAGE_luci-app-firewall=y" >> .config
     ```

3. **验证配置**：
   ```bash
   make defconfig
   ```
   这会根据 `.config` 文件生成完整的配置，自动处理依赖关系。

#### 5.3.3 配置文件示例

##### 5.3.3.1 IPQ50XX 系列设备配置示例（GL.iNet B3000）

```bash
# 目标平台配置
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq50xx=y
CONFIG_TARGET_qualcommax_ipq50xx_DEVICE_ipq5018-gl-b3000=y

# 基本功能
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_netifd=y
CONFIG_PACKAGE_procd=y
CONFIG_PACKAGE_uci=y

# NSS 相关
CONFIG_PACKAGE_kmod-ath11k=y
CONFIG_PACKAGE_kmod-qca-nss-dp=y

# LuCI 界面
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y
```

##### 5.3.3.2 IPQ60XX 系列设备配置示例（360V6）

```bash
# 目标平台配置
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq60xx=y
CONFIG_TARGET_qualcommax_ipq60xx_DEVICE_qihoo_360v6=y

# 基本功能
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_netifd=y
CONFIG_PACKAGE_procd=y
CONFIG_PACKAGE_uci=y

# NSS 相关
CONFIG_PACKAGE_kmod-ath11k=y
CONFIG_PACKAGE_kmod-qca-nss-dp=y

# LuCI 界面
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y
```

##### 5.3.3.3 IPQ807X 系列设备配置示例（小米 AX3600）

```bash
# 目标平台配置
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_ipq8071-ax3600=y

# 基本功能
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_netifd=y
CONFIG_PACKAGE_procd=y
CONFIG_PACKAGE_uci=y

# NSS 相关
CONFIG_PACKAGE_kmod-ath11k=y
CONFIG_PACKAGE_kmod-qca-nss-dp=y

# LuCI 界面
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y
```

##### 5.3.3.4 IPQ95XX 系列设备配置示例（ipq9570-kiwi-dvk）

```bash
# 目标平台配置
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq95xx=y
CONFIG_TARGET_qualcommax_ipq95xx_DEVICE_ipq9570-kiwi-dvk=y

# 基本功能
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_netifd=y
CONFIG_PACKAGE_procd=y
CONFIG_PACKAGE_uci=y

# NSS 相关
CONFIG_PACKAGE_kmod-ath11k=y
CONFIG_PACKAGE_kmod-qca-nss-dp=y

# LuCI 界面
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y
```

##### 5.3.3.5 MediaTek 系列设备配置示例（CMCC RAX3000M）

CMCC RAX3000M 采用 MediaTek MT7981B 芯片，属于 mediatek/filogic 平台。

```bash
# 目标平台配置
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_cmcc_rax3000m=y

# 基本功能
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_netifd=y
CONFIG_PACKAGE_procd=y
CONFIG_PACKAGE_uci=y

# 无线相关
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_kmod-mt7976-firmware=y
CONFIG_PACKAGE_kmod-mt7981-pci=y

# LuCI 界面
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y

# USB 支持（如果设备有 USB 接口）
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
```

### 5.4 保存配置

配置完成后，按 `Exit` 键退出，并选择 `Save` 保存配置到 `.config` 文件。

## 6. 开始编译

### 6.1 下载依赖

```bash
make download -j$(nproc)
```

### 6.2 编译固件

```bash
# 首次编译建议使用单线程，方便排查错误
make -j1 V=s

# 后续编译可以使用多线程加速
make -j$(nproc) V=s
```

### 6.3 编译结果

编译完成后，固件将位于 `bin/targets/qualcommax/` 目录下，根据选择的设备子目标和设备型号，找到对应的固件文件。

## 7. 刷入固件

### 7.1 准备工作

- 下载编译好的固件文件
- 确保设备可以进入 U-Boot 模式或 Web 界面

### 7.2 刷入方法

#### 方法一：Web 界面刷入

1. 登录设备的 Web 管理界面
2. 进入 `系统` → `备份/升级`
3. 在 `固件升级` 部分，选择编译好的固件文件
4. 点击 `刷写固件`，等待设备重启

#### 方法二：U-Boot 模式刷入

1. 设备断电，按住复位键不放，然后通电
2. 等待设备指示灯闪烁，进入 U-Boot 模式
3. 通过 TFTP 或 Web 界面上传固件
4. 执行刷入命令，等待设备重启

## 8. 配置示例

### 8.1 360V6 设备配置

```bash
# 进入配置界面
make menuconfig

# 选择目标平台
Target System → Qualcomm Atheros IPQ (ipq)
Subtarget → ipq60xx
Target Profile → qihoo_360v6

# 保存配置并编译
make -j$(nproc) V=s
```

### 8.2 小米 AX1800 设备配置

```bash
# 进入配置界面
make menuconfig

# 选择目标平台
Target System → Qualcomm Atheros IPQ (ipq)
Subtarget → ipq60xx
Target Profile → xiaomi_ax1800

# 保存配置并编译
make -j$(nproc) V=s
```

## 9. 常见问题

### 9.1 编译失败

- **问题**：编译过程中出现错误
- **解决方案**：
  1. 检查依赖是否安装完整
  2. 尝试使用单线程编译 `make -j1 V=s`，查看详细错误信息
  3. 检查网络连接，确保依赖包能够正常下载

### 9.2 固件刷入失败

- **问题**：刷入固件后设备无法启动
- **解决方案**：
  1. 检查固件是否对应设备型号
  2. 尝试进入 U-Boot 模式重新刷入
  3. 如设备变砖，尝试使用救砖工具恢复

### 9.3 NSS 加速不生效

- **问题**：固件刷入后 NSS 加速未启用
- **解决方案**：
  1. 检查配置是否启用了 NSS 相关模块
  2. 查看系统日志，确认 NSS 模块是否正常加载
  3. 检查设备是否支持 NSS 加速

## 10. 注意事项

1. **备份配置**：刷入新固件前，建议备份当前设备的配置
2. **网络连接**：编译过程需要稳定的网络连接，建议使用代理
3. **硬件兼容**：确保选择的设备型号与实际设备匹配
4. **安全设置**：首次登录后，建议修改默认密码
5. **版本更新**：定期更新源码，获取最新的 bug 修复和功能

## 11. 参考链接

- [OpenWrt 官方文档](https://openwrt.org/docs/start)
- [LibWrt GitHub 仓库](https://github.com/LiBwrt/openwrt-6.x)
- [Qualcomm IPQ 系列设备支持列表](https://github.com/LiBwrt/openwrt-6.x/tree/main/target/linux/qualcommax/dts)

---

**作者**：李杰
**生成时间**：2026-04-07
**版本**：1.0