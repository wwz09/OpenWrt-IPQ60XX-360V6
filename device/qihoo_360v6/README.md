# Qihoo 360 V6 设备支持文件

## 设备信息
- 设备型号：Qihoo 360 V6
- SoC：Qualcomm IPQ6018
- 内存：512MB DDR4
- 存储：128MB NAND Flash
- 网络：4个千兆以太网端口（1 WAN + 3 LAN）
- WiFi：支持 2.4GHz 和 5GHz 双频
- USB：1个 USB 3.0 接口

## 文件说明
- `qihoo_360v6.dts`：设备树源文件，包含所有硬件组件的配置
- `001-add-qihoo-360v6-network-config.patch`：网络配置补丁，添加设备的网络接口配置

## 编译设备树

### 方法一：使用 OpenWrt 构建系统
1. 将设备树文件复制到 OpenWrt 源码目录：
   ```bash
   cp qihoo_360v6.dts target/linux/qualcommax/dts/
   ```

2. 应用补丁：
   ```bash
   patch -p1 < 001-add-qihoo-360v6-network-config.patch
   ```

3. 配置编译选项：
   ```bash
   make menuconfig
   ```
   - 选择目标平台：`Target System -> Qualcomm Atheros IPQ60XX`
   - 选择设备：`Target Profile -> Qihoo 360 V6`

4. 编译固件：
   ```bash
   make -j$(nproc)
   ```

### 方法二：单独编译设备树

1. 安装 Device Tree Compiler (dtc)：
   ```bash
   sudo apt-get install device-tree-compiler  # Ubuntu/Debian
   # 或
   sudo yum install dtc  # CentOS/RHEL
   ```

2. 编译设备树：
   ```bash
   dtc -I dts -O dtb -o qihoo_360v6.dtb qihoo_360v6.dts
   ```

## 补丁应用

1. 确保补丁文件与目标文件路径对应
2. 进入 OpenWrt 源码根目录
3. 应用补丁：
   ```bash
   patch -p1 < device/qihoo_360v6/001-add-qihoo-360v6-network-config.patch
   ```

## 使用说明

1. 编译完成后，固件文件位于 `bin/targets/qualcommax/ipq60xx/` 目录
2. 使用 TFTP 或 Web 界面刷入固件
3. 首次启动时，设备会自动配置网络接口
4. 默认管理地址：192.168.2.1
5. 默认用户名：root，无密码

## 硬件配置说明

### GPIO 分配
- 28：复位按钮
- 29：电源 LED
- 30：2.4GHz WiFi LED
- 31：5GHz WiFi LED
- 32：WAN LED
- 33：LAN LED
- 34：MDIO MDC
- 35：MDIO MDIO

### 网络接口
- eth0：LAN 接口
- eth1：WAN 接口
- 交换机：qca8337，端口配置：1:lan, 2:lan, 3:lan, 4:wan

### 无线配置
- WiFi 0：2.4GHz 无线
- WiFi 1：5GHz 无线
- 校准变体：qihoo_360v6

## 故障排除

### 设备树编译错误
- 确保 dtc 版本正确
- 检查设备树语法是否正确
- 确认所有引用的节点在 ipq6018.dtsi 中存在

### 网络配置问题
- 检查网络补丁是否正确应用
- 确认交换机配置与硬件实际连接一致
- 检查 eth0 和 eth1 接口是否正确识别

## 注意事项
- 本设备树文件基于 OpenWrt 23.05 版本开发
- 如需在其他版本使用，可能需要调整部分配置
- 请确保使用匹配的内核版本和无线固件
