# OpenWrt-IPQ60XX-360V6

## 项目简介

这是一个为 IPQ60XX 芯片和 360V6 路由器定制的 OpenWrt 构建项目。

## 支持的设备

- 360V6
- 其他 IPQ60XX 芯片设备

## 构建步骤

1. 克隆本仓库
2. 克隆 OpenWrt 源码到 openwrt 目录
3. 运行构建脚本：`./build.sh`

## 项目结构

- `.github/workflows/` - GitHub Actions 工作流配置
- `Scripts/` - 自定义脚本
- `wrt_core/` - 核心配置和补丁
- `build.sh` - 主构建脚本
- `feeds.conf.default` - OpenWrt feeds 配置

## 作者

- 作者：李杰

## 许可证

本项目采用 MIT 许可证。
