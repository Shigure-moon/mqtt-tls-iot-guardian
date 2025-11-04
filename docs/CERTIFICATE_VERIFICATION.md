# 证书验证和EMQX TLS配置指南

## 证书状态检查结果

### 1. CA证书验证
- ✅ CA证书有效
- ✅ 证书指纹: `FA:D9:30:57:73:1C:36:89:ED:49:E4:12:DF:72:42:04:38:15:DC:E0:D0:9E:E3:77:1D:B9:4C:D6:8C:BE:9C:F9`
- ✅ 有效期: 2025-11-03 到 2035-11-01

### 2. 服务器证书验证
- ✅ 服务器证书由CA签名
- ✅ 证书验证通过: `data/certs/server.crt: OK`
- ⚠️ 服务器证书的Subject: `CN = 192.168.1.8`
- ⚠️ 服务器证书的SAN包含: `IP Address:192.168.1.8`
- ⚠️ 但设备连接到 `10.42.0.1`，证书可能不匹配

### 3. TLS连接测试
- ✅ TLS握手成功
- ✅ 证书链验证通过
- ✅ CA证书可以验证服务器证书

## 问题分析

### 设备连接成功说明
设备能够成功连接到 `10.42.0.1:8883`，说明：
1. TLS连接正常
2. 证书验证通过（设备使用了 `setInsecure()` 禁用了主机名验证）
3. EMQX的8883端口正在监听并接受TLS连接

### 可能的问题

#### 1. 服务器证书Subject不匹配
- 服务器证书的CN是 `192.168.1.8`
- 设备连接到 `10.42.0.1`
- 由于设备使用了 `setInsecure()`，只验证证书签名，不验证主机名

#### 2. EMQX TLS配置
- EMQX可能使用默认的TLS证书（自签名证书）
- 需要配置EMQX使用我们的CA签名的服务器证书

## EMQX TLS配置步骤

### 方法1: 使用环境变量配置（推荐）

```bash
# 停止EMQX容器
docker stop emqx

# 复制证书到容器可访问的位置
sudo cp data/certs/server.crt /tmp/emqx_server.crt
sudo cp data/certs/server.key /tmp/emqx_server.key
sudo cp data/certs/ca.crt /tmp/emqx_ca.crt

# 启动EMQX并配置TLS
docker run -d \
  --name emqx \
  -p 1883:1883 \
  -p 18883:8883 \
  -p 18083:18083 \
  -v /tmp/emqx_server.crt:/etc/emqx/certs/server.crt:ro \
  -v /tmp/emqx_server.key:/etc/emqx/certs/server.key:ro \
  -v /tmp/emqx_ca.crt:/etc/emqx/certs/ca.crt:ro \
  -e EMQX_LISTENER__SSL__EXTERNAL__CERTFILE=/etc/emqx/certs/server.crt \
  -e EMQX_LISTENER__SSL__EXTERNAL__KEYFILE=/etc/emqx/certs/server.key \
  -e EMQX_LISTENER__SSL__EXTERNAL__CACERTFILE=/etc/emqx/certs/ca.crt \
  emqx/emqx:latest
```

### 方法2: 通过EMQX配置文件

1. 创建EMQX配置文件目录映射
2. 编辑配置文件添加TLS监听器
3. 挂载证书文件

## 当前状态

✅ **设备连接正常**: 设备能够成功连接到MQTT服务器
✅ **TLS握手成功**: 证书验证通过
✅ **消息传输正常**: 监控脚本能看到设备消息

⚠️ **证书Subject不匹配**: 服务器证书的CN是192.168.1.8，但设备连接到10.42.0.1（由于使用了setInsecure()，这不影响连接）

## 建议

1. **短期方案（当前）**: 
   - 保持当前配置，设备已能正常连接
   - 证书验证通过，只是主机名不匹配

2. **长期方案（生产环境）**:
   - 重新生成服务器证书，包含 `10.42.0.1` 的IP地址
   - 或者配置EMQX使用正确的证书
   - 移除设备的 `setInsecure()` 调用，启用完整的主机名验证

## 验证证书

```bash
# 验证CA证书
openssl x509 -in data/certs/ca.crt -text -noout

# 验证服务器证书
openssl x509 -in data/certs/server.crt -text -noout

# 验证证书链
openssl verify -CAfile data/certs/ca.crt data/certs/server.crt

# 测试TLS连接
openssl s_client -connect 10.42.0.1:8883 -CAfile data/certs/ca.crt
```

