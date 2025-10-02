#!/bin/bash

# =================================================================
# == SCRIPT TỰ ĐỘNG HÓA ONESHOT CHO UBUNTU (PHIÊN BẢN CUỐI)    ==
# =================================================================

# Dừng script ngay lập tức nếu có lỗi xảy ra
set -e

echo "Bắt đầu quá trình cài đặt và thiết lập môi trường tự động..."
echo "Quá trình này sẽ bao gồm: Tạo swap, cập nhật hệ thống, cài đặt các gói cần thiết, Node.js, Yarn, Docker và tải mã nguồn."
echo "Vui lòng đợi..."
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
sudo apt-get update && sudo apt-get upgrade -y
echo "--- HOÀN TẤT PHẦN 2 ---" && echo ""

# PHẦN 3: CÀI ĐẶT GÓI CƠ BẢN
echo "PHẦN 3: Cài đặt các gói cơ bản..."
sudo apt-get install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip python3 python3-pip python3-venv python3-dev
echo "--- HOÀN TẤT PHẦN 3 ---" && echo ""

# PHẦN 4: CÀI ĐẶT NODE.JS
echo "PHẦN 4: Cài đặt Node.js v22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
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
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg || true; done
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd -f docker
sudo usermod -aG docker $USER
echo "--- HOÀN TẤT PHẦN 7 ---" && echo ""

# =================================================================
# == PHẦN 8: CHUẨN BỊ MÔI TRƯỜNG SCREEN VÀ HƯỚNG DẪN SỬ DỤNG   ==
# =================================================================

echo "Chuẩn bị môi trường làm việc đa nhiệm với 'screen'..."

# Tạo một session screen detached tên là 'swarm'
screen -S swarm -dm

# Tạo cửa sổ 0, đặt tên là 'docker-app' và chạy lệnh docker compose
# Lưu ý: Cần source ~/.bashrc để nhận PATH của yarn và quyền docker mới
COMMAND_TO_RUN="source ~/.bashrc && cd ~/rl-swarm && docker compose run --rm --build -Pit swarm-cpu"
screen -S swarm -p 0 -X title "docker-app"
screen -S swarm -p 0 -X stuff "$COMMAND_TO_RUN\n"

# Tạo cửa sổ 1, đặt tên là 'pinggy-tunnel', để trống chờ lệnh
screen -S swarm -X screen 1
screen -S swarm -p 1 -X title "pinggy-tunnel"
screen -S swarm -p 1 -X stuff "echo 'Cửa sổ này sẵn sàng để chạy lệnh pinggy.io khi cần.'\n"
screen -S swarm -p 1 -X stuff "echo 'Gõ lệnh ssh của bạn vào đây:'\n"

# Chọn lại cửa sổ 0 làm cửa sổ mặc định
screen -S swarm -X select 0

echo -e "\033[1;32m========================================================================\033[0m"
echo -e "\033[1;32m            MỌI QUÁ TRÌNH CÀI ĐẶT TỰ ĐỘNG ĐÃ HOÀN TẤT!            \033[0m"
echo -e "\033[1;32m========================================================================\033[0m"
echo ""
echo "Một môi trường làm việc tên là \033[1m'swarm'\033[0m đã được tạo sẵn cho bạn."
echo "Bên trong đó có 2 'tab' (cửa sổ):"
echo "  - \033[1;36mCửa sổ 0 (docker-app):\033[0m Đang chạy ứng dụng swarm."
echo "  - \033[1;36mCửa sổ 1 (pinggy-tunnel):\033[0m Chờ sẵn để bạn chạy lệnh tạo tunnel."
echo ""
echo -e "\033[1;33m>>> HƯỚNG DẪN SỬ DỤNG <<<\033[0m"
echo ""
echo -e "\033[1m1. KẾT NỐI VÀO MÔI TRƯỜNG LÀM VIỆC:\033[0m"
echo "   Gõ lệnh sau:"
echo -e "   \033[1;36mscreen -r swarm\033[0m"
echo ""
echo -e "\033[1m2. KHI ỨNG DỤNG YÊU CẦU userData.json:\033[0m"
echo "   - Nhấn tổ hợp phím \033[1;33mCtrl+A\033[0m, sau đó nhấn phím \033[1;33m1\033[0m. Bạn sẽ được chuyển sang cửa sổ 'pinggy-tunnel'."
echo "   - Chạy lệnh tunnel của bạn:"
echo -e "     \033[1;36mssh -p 443 -R0:127.0.0.1:3000 free.pinggy.io\033[0m"
echo "   - Lấy URL, truy cập web và đăng nhập."
echo ""
echo -e "\033[1m3. QUAY LẠI ỨNG DỤNG VÀ TRẢ LỜI CÂU HỎI:\033[0m"
echo "   - Nhấn tổ hợp phím \033[1;33mCtrl+A\033[0m, sau đó nhấn phím \033[1;33m0\033[0m để quay lại cửa sổ 'docker-app'."
echo "   - Trả lời các câu hỏi (N, Enter, yes)."
echo ""
echo -e "\033[1m4. ĐỂ ỨNG DỤNG CHẠY NGẦM:\033[0m"
echo "   - Nhấn tổ hợp phím \033[1;33mCtrl+A\033[0m, sau đó nhấn phím \033[1;33mD\033[0m. Bạn sẽ thoát ra ngoài và ứng dụng vẫn tiếp tục chạy."
echo ""
echo "Chúc bạn thành công!"
