#!/bin/bash

set -e

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>>> 开始安装 tufw...${NC}"

# 检测操作系统
OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
    echo -e "${RED}错误：本脚本仅支持 Linux 系统。检测到：$OS${NC}"
    exit 1
fi

# 检查并安装依赖 (ufw)
check_install_ufw() {
    if ! command -v ufw &> /dev/null; then
        echo -e "${BLUE}未检测到 ufw，正在尝试安装...${NC}"
        if [ "$(id -u)" -ne 0 ]; then
            echo -e "${RED}错误：安装依赖需要 root 权限，请使用 sudo 运行此脚本。${NC}"
            exit 1
        fi

        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y ufw
        elif command -v pacman &> /dev/null; then
            pacman -Sy --noconfirm ufw
        elif command -v dnf &> /dev/null; then
            dnf install -y ufw
        elif command -v yum &> /dev/null; then
            yum install -y ufw
        else
            echo -e "${RED}警告：无法自动安装 ufw。请手动安装后重试。${NC}"
            exit 1
        fi

        if ! command -v ufw &> /dev/null; then
             echo -e "${RED}安装 ufw 失败。${NC}"
             exit 1
        fi
        echo -e "${GREEN}ufw 安装成功。${NC}"
    else
        echo -e "${GREEN}检测到 ufw 已安装。${NC}"
    fi
}

check_install_ufw

# 检测架构
ARCH="$(uname -m)"
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    armv*)
        ARCH="arm"
        ;;
    *)
        echo -e "${RED}错误：不支持的架构：$ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}检测到系统：Linux ($ARCH)${NC}"

# 获取最新版本号
REPO="610841887/tufw" # 请根据实际情况修改仓库名
LATEST_RELEASE_URL="https://api.github.com/repos/$REPO/releases/latest"
VERSION=$(curl -s $LATEST_RELEASE_URL | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo -e "${RED}错误：无法获取最新版本号。请检查网络连接或仓库地址。${NC}"
    exit 1
fi

echo -e "${GREEN}最新版本：$VERSION${NC}"

# 构建下载链接
# 假设文件名格式为：tufw_0.1.0_linux_amd64.tar.gz (根据 .goreleaser.yaml 模板)
# 模板: {{ .ProjectName }}_{{ .Version }}_{{ .Os }}_{{ .Arch }}
# 注意：GoReleaser 生成的版本号通常不带 'v' 前缀，但 tag 可能带 'v'。
# 这里我们需要处理一下 version 字符串以匹配文件名。

CLEAN_VERSION="${VERSION#v}" # 去掉 v 前缀
FILENAME="tufw_${CLEAN_VERSION}_linux_${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$FILENAME"

echo -e "${BLUE}正在下载 $FILENAME...${NC}"
curl -L -o "$FILENAME" "$DOWNLOAD_URL"

if [ ! -f "$FILENAME" ]; then
    echo -e "${RED}下载失败。请检查网络或 URL：$DOWNLOAD_URL${NC}"
    exit 1
fi

echo -e "${BLUE}正在解压...${NC}"
tar -xzf "$FILENAME"

echo -e "${BLUE}正在安装到 /usr/local/bin...${NC}"
# 检查是否为 root，如果不是则使用 sudo
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

$SUDO mv tufw /usr/local/bin/tufw
$SUDO chmod +x /usr/local/bin/tufw

# 清理
rm "$FILENAME"
rm -f README.md LICENSE.txt # 清理可能解压出来的其他文件

echo -e "${GREEN}>>> 安装完成！${NC}"
echo -e "请使用 ${BLUE}sudo tufw${NC} 运行程序。"
