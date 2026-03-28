#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 配置管理函数

# 加载配置文件
load_config() {
    local config_file=$1
    if [ -f "$config_file" ]; then
        source "$config_file"
        log_success "Loaded config from $config_file"
    else
        log_error "Config file $config_file not found"
    fi
}

# 读取配置值
read_config() {
    local config_file=$1
    local key=$2
    local default=${3:-""}
    
    if [ -f "$config_file" ]; then
        local value=$(grep -E "^$key=" "$config_file" | cut -d '=' -f 2- | sed 's/^"\(.*\)"$/\1/')
        if [ -n "$value" ]; then
            echo "$value"
        else
            echo "$default"
        fi
    else
        echo "$default"
    fi
}

# 写入配置值
write_config() {
    local config_file=$1
    local key=$2
    local value=$3
    
    if [ -f "$config_file" ]; then
        if grep -q "^$key=" "$config_file"; then
            sed -i "s/^$key=.*/$key=$value/" "$config_file"
        else
            echo "$key=$value" >> "$config_file"
        fi
        log_success "Wrote $key=$value to $config_file"
    else
        log_error "Config file $config_file not found"
    fi
}

# 添加配置到 .config 文件
add_config() {
    local key=$1
    local value=${2:-"y"}
    
    if grep -q "^$key=" "./.config"; then
        sed -i "s/^$key=.*/$key=$value/" "./.config"
    else
        echo "$key=$value" >> "./.config"
    fi
    log_success "Added $key=$value to .config"
}

# 移除配置
remove_config() {
    local key=$1
    
    if grep -q "^$key=" "./.config"; then
        sed -i "/^$key=/d" "./.config"
        log_success "Removed $key from .config"
    else
        log_info "$key not found in .config"
    fi
}

# 启用配置
enable_config() {
    local key=$1
    add_config "$key" "y"
}

# 禁用配置
disable_config() {
    local key=$1
    add_config "$key" "n"
}

# 批量添加配置
batch_add_config() {
    local configs=($@)
    for config in "${configs[@]}"; do
        add_config "$config"
    done
}

# 批量禁用配置
batch_disable_config() {
    local configs=($@)
    for config in "${configs[@]}"; do
        disable_config "$config"
    done
}

# 检查配置是否存在
check_config() {
    local key=$1
    if grep -q "^$key=" "./.config"; then
        return 0
    else
        return 1
    fi
}

# 检查配置是否启用
is_config_enabled() {
    local key=$1
    if grep -q "^$key=y" "./.config"; then
        return 0
    else
        return 1
    fi
}

# 检查配置是否禁用
is_config_disabled() {
    local key=$1
    if grep -q "^$key=n" "./.config"; then
        return 0
    else
        return 1
    fi
}

# 生成配置文件
generate_config() {
    local config_file=$1
    local configs=($@)
    
    > "$config_file"
    for config in "${configs[@]:1}"; do
        echo "$config" >> "$config_file"
    done
    log_success "Generated config file $config_file"
}

# 合并配置文件
merge_config() {
    local dest=$1
    local sources=($@)
    
    for source in "${sources[@]:1}"; do
        if [ -f "$source" ]; then
            cat "$source" >> "$dest"
            log_success "Merged $source into $dest"
        else
            log_error "Source config $source not found"
        fi
    done
}

# 备份配置文件
backup_config() {
    local config_file=$1
    local backup_file="${config_file}.bak"
    
    if [ -f "$config_file" ]; then
        cp -f "$config_file" "$backup_file"
        log_success "Backed up $config_file to $backup_file"
    else
        log_error "Config file $config_file not found"
    fi
}

# 恢复配置文件
restore_config() {
    local config_file=$1
    local backup_file="${config_file}.bak"
    
    if [ -f "$backup_file" ]; then
        cp -f "$backup_file" "$config_file"
        log_success "Restored $config_file from $backup_file"
    else
        log_error "Backup file $backup_file not found"
    fi
}
