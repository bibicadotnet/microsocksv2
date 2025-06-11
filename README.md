# microsocksv2

Phiên bản Microsocks-v2 bổ xung tính năng quản lý tốc độ download và upload

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
      - SYS_MODULE
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
      - SYS_MODULE
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
      - SYS_MODULE
    environment:
      - PORT=1080
      - AUTH_ONCE=true
      - QUIET=true
      - USERNAME=taikhoan3
      - PASSWORD=taikhoan3
    logging:
      driver: "none"
```
