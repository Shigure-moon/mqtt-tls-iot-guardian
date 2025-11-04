# 证书加密存储说明

## 概述

系统已实现设备证书和私钥的加密存储功能。所有存储在数据库中的证书和私钥都会使用 Fernet 对称加密进行加密，确保敏感数据的安全性。

## 加密方式

- **加密算法**: Fernet (基于 AES 128 的对称加密)
- **密钥派生**: 使用 PBKDF2-HMAC-SHA256 从密码派生密钥
- **密钥来源**: 优先使用 `CERT_ENCRYPTION_KEY`，否则使用 `JWT_SECRET_KEY` 派生

## 配置说明

### 方式一：使用专门的加密密钥（推荐）

在 `backend/.env` 文件中添加：

```bash
# 证书加密密钥（可选，如果不设置则使用 JWT_SECRET_KEY 派生）
CERT_ENCRYPTION_KEY=xNgCIZhjpEb7A4muT6PvCp3bhwfSvxwab_wM1qMK9fI=
```

**生成新的加密密钥**：

```bash
python3 -c "from cryptography.fernet import Fernet; key = Fernet.generate_key(); print('CERT_ENCRYPTION_KEY=' + key.decode())"
```

### 方式二：使用 JWT_SECRET_KEY 派生（默认）

如果不设置 `CERT_ENCRYPTION_KEY`，系统会自动使用 `JWT_SECRET_KEY` 通过 PBKDF2 算法派生加密密钥。

## 向后兼容

系统会自动检测已存储的证书数据：
- 如果数据以 `-----BEGIN` 开头（PEM 格式），视为未加密的旧数据，直接返回
- 如果解密失败，视为未加密的旧数据，直接返回
- 新生成的证书会自动加密存储

## 安全建议

1. **密钥管理**：
   - 将 `CERT_ENCRYPTION_KEY` 存储在安全的地方（如密钥管理服务）
   - 不要将密钥提交到版本控制系统
   - 定期轮换密钥（需要重新加密现有数据）

2. **环境变量**：
   - 使用环境变量或密钥管理工具管理敏感配置
   - 生产环境使用专门的密钥管理服务

3. **备份**：
   - 备份加密密钥到安全位置
   - 丢失密钥将无法解密已存储的证书

## 使用示例

系统会在以下场景自动使用加密：

1. **生成证书时**：`DeviceService.add_certificate()` 会自动加密证书和私钥
2. **读取证书时**：API 端点会自动解密证书数据返回给前端
3. **存储证书时**：数据库中的证书和私钥字段都是加密后的数据

## 注意事项

- 加密密钥一旦丢失，已加密的数据将无法恢复
- 建议在生产环境使用专门的密钥管理服务（如 AWS KMS、Azure Key Vault 等）
- 定期备份密钥到安全位置

