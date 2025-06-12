# 🧦 MicroSocks v2 — SOCKS5 proxy with bandwidth control

**MicroSocks v2** là phiên bản nâng cấp của [microsocks](https://github.com/rofl0r/microsocks), được tích hợp sẵn công cụ `tc` (Traffic Control) giúp giới hạn **tốc độ upload** và **download** trực tiếp trong container.

Giải pháp này phù hợp khi bạn:

- Muốn cấp SOCKS5 riêng biệt cho từng người dùng qua Docker.
- Cần hạn chế người dùng chiếm dụng quá nhiều băng thông.
- Triển khai proxy nhanh trên VPS hoặc hạ tầng container hóa.

> 📦 Image build sẵn: [`bibica/microsocks-v2`](https://hub.docker.com/r/bibica/microsocks-v2)

---

## 🚀 Cài đặt nhanh

Chạy script tự động:

```bash
wget -qO microsocks_v2.sh https://go.bibica.net/microsocks_v2 && bash microsocks_v2.sh
````

Script sẽ làm tự động mọi thứ, muốn tạo bao nhiêu tài khoản, giới hạn từng tài khoản download/upload như nào thì chạy lại script là được

---

## 🛠 Cài đặt thủ công

Tạo file `compose.yml`:

```yaml
services:
  taikhoan1:
    image: bibica/microsocks-v2
    container_name: taikhoan1
    restart: always
    ports:
      - "10001:1080"  # Cổng host:container
    cap_add:
      - NET_ADMIN     # Cần để chạy tc, modprobe, ip trong container
    environment:
      - PORT=1080
      - AUTH_ONCE=true
      - QUIET=true
      - USERNAME=taikhoan1
      - PASSWORD=taikhoan1
      - DOWNLOAD_RATE=10Mbps
      - UPLOAD_RATE=10Mbps
    logging:
      driver: "none"
```

Khởi chạy container:

```bash
docker compose up -d
```

---

## 👥 Tạo nhiều user

Chỉ cần copy phần `services`, đổi các thông số:

* `container_name`
* `USERNAME`, `PASSWORD`
* `ports`
* (tuỳ chọn) tốc độ `DOWNLOAD_RATE`, `UPLOAD_RATE`

Ví dụ:

```yaml
  taikhoan2:
    image: bibica/microsocks-v2
    container_name: taikhoan2
    ports:
      - "10002:1080"
    cap_add:
      - NET_ADMIN
    environment:
      - PORT=1080
      - USERNAME=taikhoan2
      - PASSWORD=taikhoan2
      - DOWNLOAD_RATE=20Mbps
      - UPLOAD_RATE=20Mbps
    logging:
      driver: "none"

  taikhoan3:
    image: bibica/microsocks-v2
    container_name: taikhoan3
    ports:
      - "10003:1080"
    cap_add:
      - NET_ADMIN
    environment:
      - PORT=1080
      - USERNAME=taikhoan3
      - PASSWORD=taikhoan3
      # Không giới hạn tốc độ
    logging:
      driver: "none"
```

---

## 🧪 Kiểm tra hoạt động của proxy

Dùng `curl` để kiểm tra SOCKS5 proxy (bản tự động đã có sẵn):

```bash
curl -x socks5h://taikhoan1:taikhoan1@localhost:10001 http://ifconfig.me
```

---

## ⚙️ Biến môi trường hỗ trợ

| Biến                   | Ý nghĩa                                    |
| ---------------------- | ------------------------------------------ |
| `PORT`                 | Cổng lắng nghe của SOCKS5 (mặc định: 1080) |
| `USERNAME`, `PASSWORD` | Tài khoản xác thực SOCKS5                  |
| `DOWNLOAD_RATE`        | Giới hạn tốc độ tải xuống (VD: `10Mbps`)   |
| `UPLOAD_RATE`          | Giới hạn tốc độ tải lên                    |
| `AUTH_ONCE=true`       | Xác thực một lần duy nhất                  |
| `QUIET=true`           | Ẩn log đầu ra                              |

---

## 🧰 Yêu cầu hệ thống

* Docker (>= 20.10)
* Container phải có quyền `NET_ADMIN` để cấu hình băng thông

---
