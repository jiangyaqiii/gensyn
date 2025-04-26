#!/bin/bash
set -e

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
  echo "请使用sudo运行此脚本"
  exit 1
fi

# 检查系统内存
total_mem=$(free -g | awk '/^Mem:/{print $2}')
if [ "$total_mem" -lt 16 ]; then
  echo "错误: 系统内存小于16GB (当前: ${total_mem}GB)"
  echo "请确保系统至少有16GB内存后再运行"
  exit 1
fi

echo "系统内存检查通过: ${total_mem}GB"

# 1. 更新系统包
echo "正在更新系统包..."
apt-get update && apt-get upgrade -y

# 2. 安装通用工具
echo "正在安装通用工具..."
apt install screen curl iptables build-essential git wget lz4 jq make gcc nano \
  automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev \
  libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# 3. 安装Python
echo "正在安装Python..."
apt-get install python3 python3-pip python3-venv python3-dev -y

# 4. 安装Node
echo "正在安装Node.js..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g yarn

# 5. 安装Yarn
echo "正在安装Yarn..."
su - $SUDO_USER -c "curl -o- -L https://yarnpkg.com/install.sh | bash"

# 添加Yarn到PATH
echo 'export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"' >> /home/$SUDO_USER/.bashrc

# 检查必要的环境变量
if [ -z "$HUGGINGFACE_TOKEN" ]; then
  echo "错误: 未设置HUGGINGFACE_TOKEN环境变量"
  echo "请先设置HUGGINGFACE_TOKEN环境变量:"
  read -p '你的HuggingFace访问令牌:' HUGGINGFACE_TOKEN
  # echo "export HUGGINGFACE_TOKEN='你的HuggingFace访问令牌'"
  exit 1
fi

# 克隆仓库并设置环境
echo "正在克隆仓库..."
cd /home/$SUDO_USER
su - $SUDO_USER -c "git clone https://github.com/gensyn-ai/rl-swarm/"
cd rl-swarm

# 创建并激活虚拟环境
echo "正在设置Python虚拟环境..."
su - $SUDO_USER -c "cd rl-swarm && python3 -m venv .venv"
su - $SUDO_USER -c "cd rl-swarm && source .venv/bin/activate && ./run_rl_swarm.sh -y"

echo "安装完成！"
