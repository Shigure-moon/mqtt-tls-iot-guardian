#!/usr/bin/env python3
"""
测试证书生成功能
"""
import sys
from pathlib import Path

# 添加backend目录到路径
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

import asyncio
from app.services.certificate import CertificateService


def test_ca_certificate():
    """测试CA证书生成"""
    print("=" * 60)
    print("测试CA证书生成")
    print("=" * 60)
    
    try:
        ca_key, ca_cert = CertificateService.generate_ca_certificate()
        print("✅ CA证书生成成功")
        print(f"密钥长度: {len(ca_key)} 字符")
        print(f"证书长度: {len(ca_cert)} 字符")
        print("\nCA证书内容（前100字符）:")
        print(ca_cert[:100] + "...")
        return True
    except Exception as e:
        print(f"❌ CA证书生成失败: {e}")
        return False


def test_server_certificate():
    """测试服务器证书生成"""
    print("\n" + "=" * 60)
    print("测试服务器证书生成")
    print("=" * 60)
    
    try:
        server_key, server_cert = CertificateService.generate_server_certificate(
            common_name="mosquitto-broker",
            alt_names=["localhost", "127.0.0.1"],
            validity_days=365
        )
        print("✅ 服务器证书生成成功")
        print(f"密钥长度: {len(server_key)} 字符")
        print(f"证书长度: {len(server_cert)} 字符")
        print("\n服务器证书内容（前100字符）:")
        print(server_cert[:100] + "...")
        return True
    except Exception as e:
        print(f"❌ 服务器证书生成失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_client_certificate():
    """测试客户端证书生成"""
    print("\n" + "=" * 60)
    print("测试客户端证书生成")
    print("=" * 60)
    
    try:
        client_key, client_cert, serial_number = CertificateService.generate_client_certificate(
            device_id="test-device-001",
            common_name="device-001",
            validity_days=365
        )
        print("✅ 客户端证书生成成功")
        print(f"密钥长度: {len(client_key)} 字符")
        print(f"证书长度: {len(client_cert)} 字符")
        print(f"序列号: {serial_number}")
        print("\n客户端证书内容（前100字符）:")
        print(client_cert[:100] + "...")
        return True
    except Exception as e:
        print(f"❌ 客户端证书生成失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_ca_download():
    """测试CA证书下载"""
    print("\n" + "=" * 60)
    print("测试CA证书下载")
    print("=" * 60)
    
    try:
        ca_cert = CertificateService.get_ca_certificate()
        if ca_cert:
            print("✅ CA证书下载成功")
            print(f"证书长度: {len(ca_cert)} 字符")
            return True
        else:
            print("⚠️  CA证书不存在")
            return False
    except Exception as e:
        print(f"❌ CA证书下载失败: {e}")
        return False


def test_certificate_verification():
    """测试证书验证"""
    print("\n" + "=" * 60)
    print("测试证书验证")
    print("=" * 60)
    
    try:
        # 生成一个测试证书
        client_key, client_cert, _ = CertificateService.generate_client_certificate(
            device_id="test-verify-001",
            common_name="test-certificate",
            validity_days=365
        )
        
        # 验证证书
        is_valid, error = CertificateService.verify_certificate(client_cert)
        if is_valid:
            print("✅ 证书验证成功")
        else:
            print(f"⚠️  证书验证失败: {error}")
        return is_valid
    except Exception as e:
        print(f"❌ 证书验证测试失败: {e}")
        return False


def main():
    """主函数"""
    print("\n" + "=" * 60)
    print("IoT安全管理系统 - 证书功能测试")
    print("=" * 60 + "\n")
    
    results = []
    
    # 测试CA证书生成
    results.append(("CA证书生成", test_ca_certificate()))
    
    # 测试服务器证书生成
    results.append(("服务器证书生成", test_server_certificate()))
    
    # 测试客户端证书生成
    results.append(("客户端证书生成", test_client_certificate()))
    
    # 测试CA证书下载
    results.append(("CA证书下载", test_ca_download()))
    
    # 测试证书验证
    results.append(("证书验证", test_certificate_verification()))
    
    # 汇总结果
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"{test_name}: {status}")
        if result:
            passed += 1
    
    print("\n" + "-" * 60)
    print(f"总计: {passed}/{total} 测试通过")
    print("-" * 60)
    
    if passed == total:
        print("\n🎉 所有测试通过！")
        return 0
    else:
        print(f"\n⚠️  {total - passed} 个测试失败")
        return 1


if __name__ == "__main__":
    sys.exit(main())

