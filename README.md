# microsocksv2

Phiên bản Microsocks-v2 bổ xung tính năng quản lý tốc độ download và upload

Tình huống giả định là bạn tạo 1 VPS riêng để chạy socks5, muốn hạn chế 1 số user, tránh họ download/upload quá nhiều, ảnh hưởng tới toàn hệ thống, có thể dùng bản v2, để có thêm tính năng này

- Tạo 1 file `compose.yml`, nội dung cơ bản như bên dưới

```
services:
  taikhoan1:
    image: bibica/microsocks-v2
    container_name: taikhoan1
    restart: always
    ports:
      - "10001:1080"
    cap_add:
      - NET_ADMIN
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
- Trong đó 2 giá trị mới là `DOWNLOAD_RATE=10Mbps` và `UPLOAD_RATE=10Mbps`, port kết nối là `10001`

Tạo thêm các user khác, thì cứ copy hết toàn bộ nội dung trên, trừ dòng `services`, thay port khác

- ví dụ bên dưới tạo thêm user `taikhoan2` chạy ở port `10002` với giới hạn `20 Mbps`, `taikhoan3` chạy ở port `10003` không giới hạn gì cả

```
services:
  taikhoan1:
    image: bibica/microsocks-v2
    container_name: taikhoan1
    restart: always
    ports:
      - "10001:1080"
    cap_add:
      - NET_ADMIN
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

  taikhoan2:
    image: bibica/microsocks-v2
    container_name: taikhoan2
    restart: always
    ports:
      - "10002:1080"
    cap_add:
      - NET_ADMIN
    environment:
      - PORT=1080
      - AUTH_ONCE=true
      - QUIET=true
      - USERNAME=taikhoan2
      - PASSWORD=taikhoan2
      - DOWNLOAD_RATE=20Mbps
      - UPLOAD_RATE=20Mbps
    logging:
      driver: "none"

  taikhoan3:
    image: bibica/microsocks-v2
    container_name: taikhoan3
    restart: always
    ports:
      - "10003:1080"
    cap_add:
      - NET_ADMIN
    environment:
      - PORT=1080
      - AUTH_ONCE=true
      - QUIET=true
      - USERNAME=taikhoan3
      - PASSWORD=taikhoan3
    logging:
      driver: "none"
```
