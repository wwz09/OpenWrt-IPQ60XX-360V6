#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 公共工具函数

# 日志函数
log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# 检查文件是否存在
check_file() {
    if [ -f "$1" ]; then
        return 0
    else
        return 1
    fi
}

# 检查目录是否存在
check_dir() {
    if [ -d "$1" ]; then
        return 0
    else
        return 1
    fi
}

# 安全执行 sed 命令
safe_sed() {
    local file=$1
    local pattern=$2
    local replacement=$3
    
    if check_file "$file"; then
        sed -i "$pattern" "$replacement" "$file"
        log_success "Modified $file"
    else
        log_error "File $file not found"
    fi
}

# 查找文件
find_file() {
    local pattern=$1
    local path=${2:-"."}
    find "$path" -type f -name "$pattern" 2>/dev/null
}

# 查找目录
find_dir() {
    local pattern=$1
    local path=${2:-"."}
    find "$path" -type d -name "$pattern" 2>/dev/null
}

# 克隆仓库
clone_repo() {
    local repo=$1
    local branch=$2
    local dest=${3:-"${repo##*/}"}
    
    if check_dir "$dest"; then
        log_info "Directory $dest already exists, skipping clone"
        return
    fi
    
    git clone --depth=1 --single-branch --branch "$branch" "https://github.com/$repo.git" "$dest"
    if [ $? -eq 0 ]; then
        log_success "Cloned $repo to $dest"
    else
        log_error "Failed to clone $repo"
    fi
}

# 清理目录
clean_dir() {
    local dir=$1
    if check_dir "$dir"; then
        rm -rf "$dir"
        log_success "Cleaned directory $dir"
    else
        log_info "Directory $dir does not exist"
    fi
}

# 复制文件
copy_file() {
    local src=$1
    local dest=$2
    
    if check_file "$src"; then
        cp -f "$src" "$dest"
        log_success "Copied $src to $dest"
    else
        log_error "Source file $src not found"
    fi
}

# 移动文件
move_file() {
    local src=$1
    local dest=$2
    
    if check_file "$src"; then
        mv -f "$src" "$dest"
        log_success "Moved $src to $dest"
    else
        log_error "Source file $src not found"
    fi
}

# 下载文件
download_file() {
    local url=$1
    local dest=$2
    
    if command -v curl >/dev/null 2>&1; then
        curl -sL "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$dest"
    else
        log_error "Neither curl nor wget found"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Downloaded $url to $dest"
    else
        log_error "Failed to download $url"
    fi
}

# 执行命令并检查结果
exec_command() {
    local cmd=$1
    local desc=${2:-"Executing command"}
    
    log_info "$desc"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log_success "$desc completed successfully"
    else
        log_error "$desc failed"
    fi
}

# 加载环境变量
load_env() {
    local env_file=$1
    if check_file "$env_file"; then
        source "$env_file"
        log_success "Loaded environment from $env_file"
    else
        log_error "Environment file $env_file not found"
    fi
}

# 导出环境变量
export_env() {
    local key=$1
    local value=$2
    export "$key=$value"
    echo "$key=$value" >> "$GITHUB_ENV"
    log_info "Exported $key=$value"
}
