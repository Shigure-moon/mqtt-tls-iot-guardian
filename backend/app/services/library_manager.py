"""
Arduino库文件管理服务
管理本地Arduino库文件，支持编译时自动包含依赖库
"""
import json
import logging
from pathlib import Path
from typing import List, Dict, Optional
from app.core.config import settings

logger = logging.getLogger(__name__)


class LibraryManager:
    """Arduino库文件管理器"""
    
    def __init__(self, libraries_dir: Optional[Path] = None):
        """
        初始化库管理器
        
        Args:
            libraries_dir: 库文件目录路径，默认为项目根目录下的libraries目录
        """
        if libraries_dir is None:
            # 从backend目录向上查找项目根目录
            project_root = Path(__file__).parent.parent.parent.parent
            libraries_dir = project_root / "libraries"
        
        self.libraries_dir = Path(libraries_dir)
        if not self.libraries_dir.exists():
            logger.warning(f"库文件目录不存在: {self.libraries_dir}")
            self.libraries_dir.mkdir(parents=True, exist_ok=True)
    
    def get_library_path(self, library_name: str) -> Optional[Path]:
        """
        获取库文件路径
        
        Args:
            library_name: 库名称（如：PubSubClient）
            
        Returns:
            库文件路径，如果不存在则返回None
        """
        library_path = self.libraries_dir / library_name
        if library_path.exists() and library_path.is_dir():
            return library_path
        return None
    
    def list_available_libraries(self) -> List[str]:
        """
        列出所有可用的库
        
        Returns:
            库名称列表
        """
        if not self.libraries_dir.exists():
            return []
        
        libraries = []
        for item in self.libraries_dir.iterdir():
            if item.is_dir():
                # 检查是否是有效的Arduino库（包含library.properties）
                props_file = item / "library.properties"
                if props_file.exists():
                    libraries.append(item.name)
        
        return sorted(libraries)
    
    def get_library_info(self, library_name: str) -> Optional[Dict]:
        """
        获取库信息（从library.properties）
        
        Args:
            library_name: 库名称
            
        Returns:
            库信息字典，包含name, version, author等
        """
        library_path = self.get_library_path(library_name)
        if not library_path:
            return None
        
        props_file = library_path / "library.properties"
        if not props_file.exists():
            return None
        
        info = {"name": library_name, "path": str(library_path)}
        
        # 解析library.properties
        try:
            with open(props_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if '=' in line and not line.startswith('#'):
                        key, value = line.split('=', 1)
                        info[key.strip()] = value.strip()
        except Exception as e:
            logger.warning(f"解析库属性失败 {library_name}: {e}")
        
        return info
    
    def parse_required_libraries(self, template_code: str) -> List[str]:
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
    
    def get_compile_library_args(self, required_libraries: List[str]) -> List[str]:
        """
        获取编译时需要的库参数列表（用于arduino-cli --library参数）
        
        Args:
            required_libraries: 所需库名称列表
            
        Returns:
            arduino-cli --library参数列表
        """
        args = []
        missing_libraries = []
        
        for lib_name in required_libraries:
            lib_path = self.get_library_path(lib_name)
            if lib_path:
                args.extend(['--library', str(lib_path)])
            else:
                missing_libraries.append(lib_name)
        
        if missing_libraries:
            logger.warning(f"以下库文件缺失: {missing_libraries}")
            logger.info(f"可用库: {self.list_available_libraries()}")
        
        return args
    
    def get_libraries_from_template(self, required_libraries_json: Optional[str]) -> List[str]:
        """
        从模板的required_libraries字段解析库列表
        
        Args:
            required_libraries_json: JSON格式的库列表字符串
            
        Returns:
            库名称列表
        """
        if not required_libraries_json:
            return []
        
        try:
            lib_data = json.loads(required_libraries_json)
            if isinstance(lib_data, dict) and 'libraries' in lib_data:
                return [lib.get('name', '') for lib in lib_data['libraries'] if lib.get('name')]
            elif isinstance(lib_data, list):
                return [lib.get('name', '') if isinstance(lib, dict) else str(lib) for lib in lib_data]
        except json.JSONDecodeError as e:
            logger.warning(f"解析库列表JSON失败: {e}")
        
        return []
    
    def validate_libraries(self, required_libraries: List[str]) -> Dict[str, bool]:
        """
        验证所需库是否都存在
        
        Args:
            required_libraries: 所需库名称列表
            
        Returns:
            字典，键为库名，值为是否存在
        """
        result = {}
        for lib_name in required_libraries:
            result[lib_name] = self.get_library_path(lib_name) is not None
        return result

