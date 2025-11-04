"""
固件构建服务
处理固件编译、加密和二进制文件生成
"""
import os
import subprocess
import hashlib
import logging
from pathlib import Path
from typing import Optional, Dict, Tuple, List
from app.services.firmware_encryption import FirmwareEncryptionService
from app.services.firmware import FirmwareService
# 不再使用本地库管理器，改用Arduino CLI远程管理
# from app.services.library_manager import LibraryManager
from app.core.encryption import encrypt_certificate_data

logger = logging.getLogger(__name__)


class FirmwareBuildService:
    """固件构建服务"""
    
    def __init__(self, firmware_dir: Optional[str] = None):
        """
        初始化固件构建服务
        
        Args:
            firmware_dir: 固件存储目录
        """
        if firmware_dir is None:
            project_root = Path(__file__).parent.parent.parent.parent
            firmware_dir = project_root / "data" / "firmware"
        
        self.firmware_dir = Path(firmware_dir)
        self.firmware_dir.mkdir(parents=True, exist_ok=True)
        
        self.encryption_service = FirmwareEncryptionService(str(self.firmware_dir))
    
    def calculate_file_hash(self, file_path: str) -> str:
        """
        计算文件SHA256哈希
        
        Args:
            file_path: 文件路径
            
        Returns:
            SHA256哈希值（十六进制字符串）
        """
        sha256 = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256.update(chunk)
        return sha256.hexdigest()
    
    async def build_firmware_code(
        self,
        device_id: str,
        device_name: str,
        device_type: str,
        wifi_ssid: str,
        wifi_password: str,
        mqtt_server: str,
        ca_cert: Optional[str] = None,
        template_id: Optional[str] = None,
        db: Optional[any] = None
    ) -> str:
        """
        生成固件代码（Arduino .ino文件）
        
        Args:
            device_id: 设备ID
            device_name: 设备名称
            device_type: 设备类型
            wifi_ssid: WiFi SSID
            wifi_password: WiFi密码
            mqtt_server: MQTT服务器地址
            ca_cert: CA证书内容
            template_id: 模板ID
            db: 数据库会话
            
        Returns:
            固件代码文件路径
        """
        # 生成固件代码
        firmware_code = await FirmwareService.generate_firmware_code(
            device_id=device_id,
            device_name=device_name,
            device_type=device_type,
            wifi_ssid=wifi_ssid,
            wifi_password=wifi_password,
            mqtt_server=mqtt_server,
            ca_cert=ca_cert,
            template_id=template_id,
            db=db
        )
        
        # 保存为.ino文件
        firmware_file = self.firmware_dir / f"{device_id}.ino"
        firmware_file.write_text(firmware_code, encoding='utf-8')
        
        logger.info(f"固件代码已生成: {firmware_file}")
        return str(firmware_file)
    
    def compile_firmware(
        self,
        ino_file_path: str,
        output_path: Optional[str] = None,
        arduino_cli_path: Optional[str] = None,
        required_libraries: Optional[List[str]] = None,
        fqbn: str = "esp8266:esp8266:nodemcuv2"
    ) -> Tuple[Optional[str], str]:
        """
        编译Arduino固件为二进制文件
        
        Args:
            ino_file_path: .ino文件路径
            output_path: 输出.bin文件路径
            arduino_cli_path: arduino-cli可执行文件路径
            required_libraries: 所需库列表（如果为None，则从代码中解析）
            fqbn: 板型标识（Fully Qualified Board Name）
            
        Returns:
            (编译后的.bin文件路径, 编译日志)，如果失败则返回(None, 错误日志)
        """
        ino_file = Path(ino_file_path)
        if not ino_file.exists():
            error_msg = f"固件文件不存在: {ino_file_path}"
            logger.error(error_msg)
            return None, error_msg
        
        # 确定输出路径
        build_dir = self.firmware_dir / "build" / ino_file.stem
        build_dir.mkdir(parents=True, exist_ok=True)
        
        if output_path is None:
            output_path = self.firmware_dir / "output" / f"{ino_file.stem}.bin"
        else:
            output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # 查找arduino-cli
        if arduino_cli_path is None:
            arduino_cli_path = self._find_arduino_cli()
        
        if not arduino_cli_path:
            error_msg = "未找到arduino-cli，跳过编译步骤"
            logger.warning(error_msg)
            logger.info("提示：可以手动编译固件，或安装arduino-cli后自动编译")
            return None, error_msg
        
        # 使用Arduino CLI远程安装和管理库
        # 如果未提供库列表，从代码中解析
        if required_libraries is None:
            template_code = ino_file.read_text(encoding='utf-8')
            required_libraries = self._parse_required_libraries(template_code)
        
        # 安装所需的库（使用Arduino CLI）
        if required_libraries:
            self._install_libraries_remote(arduino_cli_path, required_libraries)
            logger.info(f"使用远程库: {required_libraries}")
        
        try:
            # 构建arduino-cli编译命令
            cmd = [
                arduino_cli_path,
                "compile",
                "--fqbn", fqbn,
                "--build-path", str(build_dir),
                "--output-dir", str(output_path.parent),
            ]
            
            # Arduino CLI会自动使用已安装的库，无需手动指定路径
            
            # 添加源文件目录
            cmd.append(str(ino_file.parent))
            
            logger.info(f"执行编译命令: {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600  # 10分钟超时
            )
            
            build_log = result.stdout + result.stderr
            
            if result.returncode == 0:
                # 查找生成的.bin文件
                # arduino-cli通常在build目录生成firmware.bin
                possible_bin_files = [
                    build_dir / "firmware.bin",
                    output_path.parent / f"{ino_file.stem}.bin",
                    output_path.parent / "firmware.bin",
                ]
                
                bin_file = None
                for possible_path in possible_bin_files:
                    if possible_path.exists():
                        bin_file = possible_path
                        break
                
                if bin_file:
                    # 复制到输出目录
                    output_path.parent.mkdir(parents=True, exist_ok=True)
                    final_bin_path = output_path.parent / f"{ino_file.stem}.bin"
                    import shutil
                    shutil.copy2(bin_file, final_bin_path)
                    logger.info(f"固件编译成功: {final_bin_path}")
                    return str(final_bin_path), build_log
                else:
                    error_msg = "编译成功但未找到.bin文件"
                    logger.warning(error_msg)
                    logger.debug(f"编译日志: {build_log}")
                    return None, f"{error_msg}\n{build_log}"
            else:
                error_msg = f"固件编译失败: {result.stderr}"
                logger.error(error_msg)
                logger.debug(f"编译日志: {build_log}")
                return None, f"{error_msg}\n{build_log}"
                
        except subprocess.TimeoutExpired:
            error_msg = "固件编译超时（超过10分钟）"
            logger.error(error_msg)
            return None, error_msg
        except Exception as e:
            error_msg = f"固件编译异常: {e}"
            logger.error(error_msg, exc_info=True)
            return None, error_msg
    
    def _find_arduino_cli(self) -> Optional[str]:
        """查找arduino-cli可执行文件"""
        possible_paths = [
            "arduino-cli",
            "/usr/local/bin/arduino-cli",
            "/usr/bin/arduino-cli",
            "~/.local/bin/arduino-cli",
        ]
        
        for path in possible_paths:
            expanded_path = os.path.expanduser(path)
            if os.path.exists(expanded_path) and os.access(expanded_path, os.X_OK):
                return expanded_path
        
        # 尝试使用which命令
        try:
            result = subprocess.run(
                ["which", "arduino-cli"],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                return result.stdout.strip()
        except:
            pass
        
        return None
    
    def _parse_required_libraries(self, template_code: str) -> List[str]:
        """
        从模板代码中解析所需库（通过#include语句）
        
        Args:
            template_code: 模板代码内容
            
        Returns:
            库名称列表
        """
        libraries = []
        lines = template_code.split('\n')
        
        for line in lines:
            line = line.strip()
            # 匹配 #include <LibraryName.h> 或 #include "LibraryName.h"
            if line.startswith('#include'):
                # 提取库名
                if '<' in line and '>' in line:
                    # #include <LibraryName.h>
                    lib_name = line.split('<')[1].split('>')[0].replace('.h', '')
                    # 排除标准库和内置库
                    if lib_name not in ['ESP8266WiFi', 'WiFiClientSecureBearSSL', 'Arduino', 'Wire', 'SPI']:
                        libraries.append(lib_name)
        
        # 去重
        return list(set(libraries))
    
    def _install_libraries_remote(self, arduino_cli_path: str, libraries: List[str]):
        """
        使用Arduino CLI远程安装库
        
        Args:
            arduino_cli_path: arduino-cli可执行文件路径
            libraries: 库名称列表
        """
        for lib_name in libraries:
            try:
                # 检查库是否已安装
                check_cmd = [
                    arduino_cli_path,
                    "lib", "list",
                    "--format", "json"
                ]
                check_result = subprocess.run(
                    check_cmd,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                # 检查库是否已安装
                installed = False
                if check_result.returncode == 0:
                    import json
                    try:
                        lib_list = json.loads(check_result.stdout)
                        for lib in lib_list.get('installed', []):
                            if lib.get('library', {}).get('name') == lib_name:
                                installed = True
                                logger.debug(f"库 {lib_name} 已安装")
                                break
                    except json.JSONDecodeError:
                        pass
                
                # 如果未安装，则安装
                if not installed:
                    logger.info(f"正在安装库: {lib_name}")
                    install_cmd = [
                        arduino_cli_path,
                        "lib", "install", lib_name
                    ]
                    install_result = subprocess.run(
                        install_cmd,
                        capture_output=True,
                        text=True,
                        timeout=300  # 5分钟超时
                    )
                    
                    if install_result.returncode == 0:
                        logger.info(f"库 {lib_name} 安装成功")
                    else:
                        logger.warning(f"库 {lib_name} 安装失败: {install_result.stderr}")
                else:
                    logger.debug(f"库 {lib_name} 已存在，跳过安装")
                    
            except subprocess.TimeoutExpired:
                logger.warning(f"库 {lib_name} 安装超时")
            except Exception as e:
                logger.warning(f"安装库 {lib_name} 时出错: {e}")
    
    async def build_encrypted_firmware(
        self,
        device_id: str,
        device_name: str,
        device_type: str,
        wifi_ssid: str,
        wifi_password: str,
        mqtt_server: str,
        ca_cert: Optional[str] = None,
        use_encryption: bool = True,
        template_id: Optional[str] = None,
        db: Optional[any] = None
    ) -> Dict[str, any]:
        """
        构建加密固件（完整流程：生成代码 -> 编译 -> 加密）
        
        Args:
            device_id: 设备ID
            device_name: 设备名称
            device_type: 设备类型
            wifi_ssid: WiFi SSID
            wifi_password: WiFi密码
            mqtt_server: MQTT服务器地址
            ca_cert: CA证书内容
            use_encryption: 是否使用加密
            template_id: 模板ID
            db: 数据库会话
            
        Returns:
            构建结果字典
        """
        result = {
            "device_id": device_id,
            "status": "pending",
            "firmware_code_path": None,
            "firmware_bin_path": None,
            "encrypted_firmware_path": None,
            "key_hex": None,
            "errors": []
        }
        
        try:
            # 1. 生成固件代码
            logger.info(f"生成固件代码: {device_id}")
            firmware_code_path = await self.build_firmware_code(
                device_id=device_id,
                device_name=device_name,
                device_type=device_type,
                wifi_ssid=wifi_ssid,
                wifi_password=wifi_password,
                mqtt_server=mqtt_server,
                ca_cert=ca_cert,
                template_id=template_id,
                db=db
            )
            result["firmware_code_path"] = firmware_code_path
            
            # 2. 编译固件（可选，如果arduino-cli不可用则跳过）
            logger.info(f"编译固件: {device_id}")
            firmware_bin_path, build_log = self.compile_firmware(firmware_code_path)
            result["firmware_bin_path"] = firmware_bin_path
            result["build_log"] = build_log
            
            # 如果没有编译成功，使用.ino文件作为"固件"
            if not firmware_bin_path:
                logger.warning("固件编译跳过，使用.ino文件")
                firmware_bin_path = firmware_code_path
            
            # 3. 加密固件（如果启用）
            if use_encryption:
                logger.info(f"加密固件: {device_id}")
                encrypted_path, key_file, key_hex = self.encryption_service.generate_encrypted_firmware(
                    firmware_bin_path,
                    device_id,
                    use_xor_mask=True
                )
                result["encrypted_firmware_path"] = encrypted_path
                result["key_hex"] = key_hex
                result["status"] = "completed"
            else:
                result["status"] = "completed"
            
            logger.info(f"固件构建完成: {device_id}")
            
        except Exception as e:
            logger.error(f"固件构建失败: {e}", exc_info=True)
            result["status"] = "failed"
            result["errors"].append(str(e))
        
        return result

