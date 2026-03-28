# OpenWrt IPQ60XX 系列设备自动编译

## 项目简介

本项目基于 [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x) 源码仓库的 `main-nss` 分支，为 IPQ60XX 系列设备提供自动编译固件的能力。

## 支持的设备

- **IPQ60XX 系列**
  - JDCLOUD RE-SS-01
  - Qihoo 360 V6
  - Xiaomi AX1800
  - ZN M2
- **MediaTek 系列**
  - CMCC RAX3000M

## 特性

- ✅ 基于最新的 LiBwrt/openwrt-6.x 源码
- ✅ 集成 NSS 硬件加速
- ✅ 支持 WiFi 无线功能
- ✅ 集成 kenzok8/openwrt-packages 插件包
- ✅ 集成 kenzok8/jell 依赖包
- ✅ 自动云编译工作流
- ✅ 默认中文界面
- ✅ 优化的系统参数
- ✅ 自定义启动脚本

## 固件信息

- **默认IP**: 192.168.1.1
- **默认密码**: password
- **默认WiFi SSID**: OpenWrt-2.4G / OpenWrt-5G
- **WiFi密码**: 12345678

## 云编译使用方法

1. **手动触发编译**
   - 进入 GitHub Actions 页面
   - 点击 "Build OpenWrt Firmware" 工作流
   - 点击 "Run workflow"
   - 选择要编译的设备
   - 点击 "Run workflow" 开始编译

2. **定时编译**
   - 系统会每周日凌晨3点自动编译所有设备固件

3. **代码推送触发**
   - 修改 `configs/`、`.github/workflows/` 或 `scripts/` 目录下的文件时，会自动触发编译

## 本地编译方法

### 系统环境准备

推荐使用 Ubuntu 22.04 LTS 或 Debian 11 系统。

### 安装编译依赖

```bash
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
    bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
    git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev \
    libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev \
    libpython3-dev libreadline-dev libssl-dev libtool lrzsz mkisofs msmtp ninja-build \
    p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools python3-setuptools \
    qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
    vim wget xmlto xxd zlib1g-dev
```

### 编译步骤

1. **克隆源码**
   ```bash
   git clone --depth 1 https://github.com/LiBwrt/openwrt-6.x.git -b main-nss openwrt
   cd openwrt
   ```

2. **添加插件仓库**
   ```bash
   echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> feeds.conf.default
   echo "src-git jell https://github.com/kenzok8/jell" >> feeds.conf.default
   ```

3. **更新并安装feeds**
   ```bash
   ./scripts/feeds update -a
   ./scripts/feeds install -a
   ```

4. **执行DIY脚本**
   ```bash
   chmod +x ../scripts/diy-part1.sh
   chmod +x ../scripts/diy-part2.sh
   ../scripts/diy-part1.sh
   ../scripts/diy-part2.sh
   ```

5. **配置编译选项**
   ```bash
   make menuconfig
   ```

6. **下载依赖**
   ```bash
   make download -j8
   ```

7. **开始编译**
   ```bash
   make -j$(nproc) V=s
   ```

## 固件下载

编译完成后，固件文件会上传到 GitHub Actions 的 Artifacts 中，同时会创建 GitHub Release 发布固件。

## 注意事项

1. ⚠️ 首次刷机请使用 `factory` 固件
2. 🔄 系统升级请使用 `sysupgrade` 固件
3. 💾 刷机前请备份重要配置
4. ⚡ 刷机过程中请勿断电
5. 📡 本固件为自动编译生成，仅供测试使用

## 源码来源

- **主源码**: [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x)
- **插件仓库**: [kenzok8/openwrt-packages](https://github.com/kenzok8/openwrt-packages)
- **依赖仓库**: [kenzok8/jell](https://github.com/kenzok8/jell)

## 作者

- **作者**: 李杰
- **GitHub**: [wwz09](https://github.com/wwz09)

## 免责声明

本项目仅用于学习和测试目的，使用本固件造成的任何损失，作者不承担任何责任。
