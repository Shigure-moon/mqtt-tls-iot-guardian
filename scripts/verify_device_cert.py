#!/usr/bin/env python3
"""
验证设备代码中的CA证书和服务器IP配置
"""
import sys
from pathlib import Path
from cryptography import x509
from cryptography.hazmat.backends import default_backend

# 添加backend目录到Python路径
backend_dir = Path(__file__).parent.parent / "backend"
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.services.certificate import CertificateService

# 设备代码中的证书（从用户提供的代码中提取）
device_cert_pem = """-----BEGIN CERTIFICATE-----
MIIDtzCCAp+gAwIBAgIULwcUXjvNkH4JvYqzSV6LpoX3p54wDQYJKoZIhvcNAQEL
BQAwYjELMAkGA1UEBhMCQ04xEDAOBgNVBAgMB0JlaWppbmcxEDAOBgNVBAcMB0Jl
aWppbmcxHjAcBgNVBAoMFUlvVCBTZWN1cml0eSBQbGF0Zm9ybTEPMA0GA1UEAwwG
SW9UIENBMB4XDTI1MTEwNDExMzU1MloXDTI2MTEwNDExMzU1MlowbDELMAkGA1UE
BhMCQ04xEDAOBgNVBAgMB0JlaWppbmcxEDAOBgNVBAcMB0JlaWppbmcxHjAcBgNV
BAoMFUlvVCBTZWN1cml0eSBQbGF0Zm9ybTEZMBcGA1UEAwwQbW9zcXVpdHRvLWJy
b2tlcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALTa/FfoVRGc2ntz
3uxwifPIzh8BaOrvBaWuW5fPPSyaSiOFvcmlIBm4quECVcmilbniyoR4rJ0aTQhA
RZ4j8uAdwDOkl2CbfmJkYy3X6a/vXabA2BFLZ8SCJkCTGpmJTdofHbrOpXOOUl8u
UOGcXs+s1PfglGq94Eqxt2OaIvmn3/Ewx3VbSBcAkRKmOk0z+nxQse9Qmr0RLrys
5JnvvJgqiv9ek1C6cQ0PNutyah3elx460e8unCFwmwdz97gzbGCA6aSbC783l2XL
NS2gGb/7Mn01LwTieRWc5G191yubht5/J1vRoC9LOv/iknCS7N65wUYg2keda2Ch
gpsUAWsCAwEAAaNbMFkwIQYDVR0RBBowGIIQbW9zcXVpdHRvLWJyb2tlcocECioA
ATAWBgNVHSUBAf8EDDAKBggrBgEFBQcDATAOBgNVHQ8BAf8EBAMCBLAwDAYDVR0T
AQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEAoI6uMXkXDWGFQcR0GY1JAL8Mmlqh
qR3MwRofpyVBoheb0a/8kfBpl8GCsaIMpqZKwdjik1EyIxFL8SPUtNUkY/C4c3RD
Q952TuRg0BozvhDhO4bPRiNLKWi9QcQHeC7J+5DZAdcsrjbH13KQaor6zeaIszU9
qDBh0Cib9py3z3nzjlnyv99Nk++8Y8ZXUlvvM9yWx5VqKL9mVNOzOETCFLQQErI4
hTITpJ9UBzdxVo7KE0HZ0edXnOqvq1LiRldZ1RCShLG4LhYl/qqdKdHkvigWzD1t
f40g8nqXjMl9NFqw7jz/+dnug8XUTnnmo/GcV+ki6j99CSHGmvT4twWQsA==
-----END CERTIFICATE-----"""

def main():
    print("=" * 60)
    print("设备证书和IP配置验证")
    print("=" * 60)
    print()
    
    # 1. 检查系统CA证书
    print("1. 系统CA证书检查")
    print("-" * 60)
    try:
        ca_cert_pem = CertificateService.get_ca_certificate()
        if ca_cert_pem:
            ca_cert = x509.load_pem_x509_certificate(
                ca_cert_pem.encode('utf-8'),
                default_backend()
            )
            print(f"   ✅ CA证书存在")
            print(f"   Subject: {ca_cert.subject}")
            print(f"   Issuer: {ca_cert.issuer}")
            print(f"   有效期: {ca_cert.not_valid_before} 至 {ca_cert.not_valid_after}")
        else:
            print("   ❌ CA证书不存在")
            return
    except Exception as e:
        print(f"   ❌ 获取CA证书失败: {e}")
        return
    
    print()
    
    # 2. 检查设备代码中的证书
    print("2. 设备代码中的证书检查")
    print("-" * 60)
    try:
        device_cert = x509.load_pem_x509_certificate(
            device_cert_pem.encode('utf-8'),
            default_backend()
        )
        print(f"   Subject: {device_cert.subject}")
        print(f"   Issuer: {device_cert.issuer}")
        print(f"   有效期: {device_cert.not_valid_before} 至 {device_cert.not_valid_after}")
        
        # 检查是否是CA证书
        if device_cert.subject == device_cert.issuer:
            print("   ⚠️  这是自签名证书（CA证书），但设备应该使用服务器证书")
            print("   ❌ 错误：设备代码中嵌入了CA证书，应该使用服务器证书")
        else:
            print("   ✅ 这是服务器证书（由CA签名）")
            
            # 验证证书是否由系统CA签名
            ca_cert_obj = x509.load_pem_x509_certificate(
                ca_cert_pem.encode('utf-8'),
                default_backend()
            )
            try:
                ca_cert_obj.public_key().verify(
                    device_cert.signature,
                    device_cert.tbs_certificate_bytes,
                    device_cert.signature_algorithm_oid._name,
                    default_backend()
                )
                print("   ✅ 证书由系统CA签名")
            except Exception as e:
                print(f"   ❌ 证书验证失败: {e}")
                
            # 检查SAN中是否包含10.42.0.1
            try:
                san_ext = device_cert.extensions.get_extension_for_oid(
                    x509.oid.ExtensionOID.SUBJECT_ALTERNATIVE_NAME
                )
                san_names = san_ext.value
                print(f"   Subject Alternative Names: {san_names}")
                
                has_ip = False
                for name in san_names:
                    if isinstance(name, x509.IPAddress):
                        if str(name.value) == "10.42.0.1":
                            has_ip = True
                            print(f"   ✅ 包含IP地址: 10.42.0.1")
                
                if not has_ip:
                    print(f"   ⚠️  SAN中未找到IP地址: 10.42.0.1")
            except Exception as e:
                print(f"   ⚠️  无法获取SAN信息: {e}")
                
    except Exception as e:
        print(f"   ❌ 解析设备证书失败: {e}")
    
    print()
    
    # 3. 检查服务器IP
    print("3. MQTT服务器IP检查")
    print("-" * 60)
    device_ip = "10.42.0.1"
    print(f"   设备代码中的IP: {device_ip}")
    
    # 检查系统IP
    import subprocess
    result = subprocess.run(['ip', 'addr', 'show'], capture_output=True, text=True)
    if '10.42.0.1' in result.stdout:
        print(f"   ✅ 系统IP包含: 10.42.0.1")
    else:
        print(f"   ⚠️  系统IP中未找到: 10.42.0.1")
    
    # 检查MQTT端口
    print()
    print("4. MQTT端口检查")
    print("-" * 60)
    result = subprocess.run(['ss', '-tlnp'], capture_output=True, text=True)
    if ':8883' in result.stdout:
        print(f"   ✅ TLS端口8883正在监听")
    else:
        print(f"   ❌ TLS端口8883未监听")
    
    if ':1883' in result.stdout:
        print(f"   ✅ 非TLS端口1883正在监听")
    else:
        print(f"   ⚠️  非TLS端口1883未监听")
    
    print()
    print("=" * 60)
    print("验证完成")
    print("=" * 60)

if __name__ == "__main__":
    main()

