from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID

class ThreatResponseRequest(BaseModel):
    """威胁响应请求"""
    source: str = Field(..., description="威胁来源: llm_ids_agent 或 cybersentinal")
    threat_type: str = Field(..., description="威胁类型")
    severity: str = Field(..., description="严重程度: low, medium, high, critical")
    source_ip: Optional[str] = Field(None, description="源IP地址")
    device_id: Optional[str] = Field(None, description="设备ID")
    description: str = Field(..., description="威胁描述")
    raw_data: Optional[Dict[str, Any]] = Field(None, description="原始数据")
    threat_score: Optional[float] = Field(None, description="威胁评分")
    
class ThreatResponse(BaseModel):
    """威胁响应结果"""
    success: bool
    message: str
    event_id: Optional[UUID] = None
    actions_taken: list[str] = Field(default_factory=list, description="已执行的响应动作")

class DeviceIsolationRequest(BaseModel):
    """设备隔离请求"""
    device_id: str
    reason: str
    duration_minutes: Optional[int] = Field(None, description="隔离时长（分钟），None表示永久隔离")

class CertificateRevocationRequest(BaseModel):
    """证书吊销请求"""
    device_id: str
    reason: str

