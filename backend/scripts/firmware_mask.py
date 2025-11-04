#!/usr/bin/env python3
"""
固件XOR掩码处理脚本
用于对ESP8266固件应用XOR掩码，防止直接反汇编
"""
import sys
import os
import argparse
from pathlib import Path


def apply_xor_mask(firmware_path: str, key_hex: str, output_path: str = None):
    """
    对固件应用XOR掩码
    
    Args:
        firmware_path: 原始固件路径
        key_hex: XOR密钥（十六进制字符串）
        output_path: 输出路径，如果为None则自动生成
    """
    firmware_path = Path(firmware_path)
    if not firmware_path.exists():
        print(f"错误: 固件文件不存在: {firmware_path}")
        sys.exit(1)
    
    # 解析密钥
    try:
        key = bytes.fromhex(key_hex.replace(':', '').replace(' ', ''))
    except ValueError as e:
        print(f"错误: 无效的密钥格式: {e}")
        sys.exit(1)
    
    if len(key) != 16:
        print(f"错误: 密钥长度必须是16字节（128位），当前: {len(key)}")
        sys.exit(1)
    
    # 读取原始固件
    print(f"读取固件: {firmware_path}")
    with open(firmware_path, 'rb') as f:
        firmware_data = bytearray(f.read())
    
    original_size = len(firmware_data)
    print(f"固件大小: {original_size} 字节 ({original_size / 1024:.2f} KB)")
    
    # 应用XOR掩码
    print("应用XOR掩码...")
    for i in range(len(firmware_data)):
        firmware_data[i] ^= key[i % len(key)]
    
    # 确定输出路径
    if output_path is None:
        output_path = firmware_path.parent / f"{firmware_path.stem}_masked{firmware_path.suffix}"
    else:
        output_path = Path(output_path)
    
    # 写入掩码后的固件
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(firmware_data)
    
    print(f"✓ 掩码完成，输出: {output_path}")
    print(f"  大小: {len(firmware_data)} 字节 ({len(firmware_data) / 1024:.2f} KB)")
    print(f"  密钥: {key_hex}")


def remove_xor_mask(firmware_path: str, key_hex: str, output_path: str = None):
    """
    移除固件的XOR掩码（解密）
    
    Args:
        firmware_path: 掩码后的固件路径
        key_hex: XOR密钥（十六进制字符串）
        output_path: 输出路径
    """
    # XOR是可逆的，移除掩码就是再次应用掩码
    apply_xor_mask(firmware_path, key_hex, output_path)
    if output_path:
        output_path = Path(output_path)
        # 重命名输出文件
        if output_path.name.endswith('_masked.bin'):
            new_name = output_path.name.replace('_masked.bin', '_decrypted.bin')
            new_path = output_path.parent / new_name
            output_path.rename(new_path)
            print(f"✓ 解密完成，输出: {new_path}")


def main():
    parser = argparse.ArgumentParser(
        description='ESP8266固件XOR掩码处理工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 应用掩码
  python firmware_mask.py -f firmware.bin -k "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD"
  
  # 从密钥文件读取
  python firmware_mask.py -f firmware.bin -k $(cat key.txt)
  
  # 指定输出文件
  python firmware_mask.py -f firmware.bin -k "..." -o firmware_masked.bin
  
  # 移除掩码（解密）
  python firmware_mask.py -f firmware_masked.bin -k "..." --decrypt
        """
    )
    
    parser.add_argument(
        '-f', '--firmware',
        required=True,
        help='固件文件路径'
    )
    
    parser.add_argument(
        '-k', '--key',
        required=True,
        help='XOR密钥（十六进制字符串，32个字符或带冒号分隔）'
    )
    
    parser.add_argument(
        '-o', '--output',
        default=None,
        help='输出文件路径（默认：原文件名_masked.bin）'
    )
    
    parser.add_argument(
        '--decrypt',
        action='store_true',
        help='解密模式（移除掩码）'
    )
    
    args = parser.parse_args()
    
    if args.decrypt:
        remove_xor_mask(args.firmware, args.key, args.output)
    else:
        apply_xor_mask(args.firmware, args.key, args.output)


if __name__ == '__main__':
    main()

