#!/bin/bash

# =================================================================
# == SCRIPT TỰ ĐỘNG HÓA ONESHOT CHO UBUNTU                       ==
# =================================================================

# Dừng script ngay lập tức nếu có lỗi xảy ra
set -e

# Các tùy chọn để APT chạy hoàn toàn không tương tác
APT_OPTIONS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

echo "Bắt đầu quá trình cài đặt và thiết lập môi trường tự động..."
echo "Quá trình này sẽ chạy hoàn toàn không tương tác."
echo ""

# --- CÁC PHẦN 1-7 (TỰ ĐỘNG HÓA CÀI ĐẶT) ---

# PHẦN 1: TÁI TẠO SWAP
echo "PHẦN 1: Tái tạo swap file 32GB..."
sudo swapoff -a && if [ -f /swapfile ]; then sudo rm /swapfile; fi
sudo fallocate -l 32G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
if ! grep -q "/swapfile" /etc/fstab; then echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab; fi
echo "--- HOÀN TẤT PHẦN 1 ---" && echo ""

# PHẦN 2: CẬP NHẬT HỆ THỐNG
echo "PHẦN 2: Cập nhật hệ thống..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS upgrade
echo "--- HOÀN TẤT PHẦN 2 ---" && echo ""

# PHẦN 3: CÀI ĐẶT GÓI CƠ BẢN
echo "PHẦN 3: Cài đặt các gói cơ bản..."
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip python3 python3-pip python3-venv python3-dev
echo "--- HOÀN TẤT PHẦN 3 ---" && echo ""

# PHẦN 4: CÀI ĐẶT NODE.JS
echo "PHẦN 4: Cài đặt Node.js v22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install nodejs
echo "--- HOÀN TẤT PHẦN 4 ---" && echo ""

# PHẦN 5: CÀI ĐẶT YARN BERRY
echo "PHẦN 5: Cài đặt Yarn Berry và cấu hình PATH..."
curl -o- -L https://yarnpkg.com/install.sh | bash
YARN_PATH_EXPORT='export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"'
if ! grep -qF -- "$YARN_PATH_EXPORT" ~/.bashrc; then echo -e "\n# YARN PATH CONFIGURATION\n$YARN_PATH_EXPORT" >> ~/.bashrc; fi
echo "--- HOÀN TẤT PHẦN 5 ---" && echo ""

# PHẦN 6: TẢI MÃ NGUỒN
echo "PHẦN 6: Tải mã nguồn rl-swarm..."
cd "$HOME"
if [ ! -d "rl-swarm" ]; then git clone https://github.com/gensyn-ai/rl-swarm/; fi
echo "--- HOÀN TẤT PHẦN 6 ---" && echo ""

# PHẦN 7: CÀI ĐẶT DOCKER ENGINE
echo "PHẦN 7: Cài đặt Docker Engine..."
sudo apt-get update
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y $pkg || true; done
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install ca-certificates curl gnupg
# Đảm bảo các thư mục cần thiết tồn tại
sudo install -m 0755 -d /etc/apt/keyrings
sudo install -m 0755 -d /etc/apt/sources.list.d
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd -f docker
sudo usermod -aG docker $USER
echo "--- HOÀN TẤT PHẦN 7 ---" && echo ""

# =================================================================
# == PHẦN 8: KHỞI CHẠY ỨNG DỤNG                            ==
# =================================================================

echo -e "\033[1;32m========================================================================\033[0m"
echo -e "\033[1;32m      CÀI ĐẶT HOÀN TẤT! CHUẨN BỊ KHỞI CHẠY ỨNG DỤNG SWARM...            \033[0m"
echo -e "\033[1;32m========================================================================\033[0m"
echo "Script sẽ giao lại quyền kiểm soát cho bạn sau khi lệnh docker compose bắt đầu."
echo ""

# Di chuyển vào thư mục dự án
cd "$HOME/rl-swarm"

# Chạy lệnh docker compose.
# Sử dụng `sudo` để đảm bảo lệnh chạy ngay lập tức mà không cần đăng xuất/đăng nhập lại.
sudo docker compose run --rm --build -Pit swarm-cpu
