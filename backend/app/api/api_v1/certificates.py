"""
证书管理API端点
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.api_v1.auth import get_current_active_user, get_current_admin_user
from app.core.database import get_db
from app.schemas.certificate import (
    CACertificateResponse,
    ServerCertificateRequest,
    ServerCertificateResponse,
    ClientCertificateRequest,
    ClientCertificateResponse,
    CertificateVerificationRequest,
    CertificateVerificationResponse,
    CACertificateDownloadResponse,
    CertificateRevokeRequest,
    CertificateRevokeResponse
)
from app.schemas.user import User
from app.services.certificate import CertificateService
from app.services.device import DeviceService
from app.schemas.device import DeviceCertificateCreate

router = APIRouter()


@router.post("/ca/generate", response_model=CACertificateResponse)
async def generate_ca_certificate(
    current_user: User = Depends(get_current_admin_user)
) -> CACertificateResponse:
    """
    生成CA证书（仅管理员）
    """
    try:
        ca_key, ca_cert = CertificateService.generate_ca_certificate()
        return CACertificateResponse(
            ca_key=ca_key,
            ca_cert=ca_cert,
            message="CA证书已成功生成"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"生成CA证书失败: {str(e)}"
        )


@router.get("/ca/download", response_model=CACertificateDownloadResponse)
async def download_ca_certificate(
    current_user: User = Depends(get_current_active_user)
) -> CACertificateDownloadResponse:
    """
    下载CA证书
    """
    ca_cert = CertificateService.get_ca_certificate()
    if not ca_cert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="CA证书不存在，请先生成CA证书"
        )
    return CACertificateDownloadResponse(ca_cert=ca_cert)


@router.post("/ca/download/file")
async def download_ca_certificate_file(
    current_user: User = Depends(get_current_active_user)
):
    """
    下载CA证书文件（作为文件下载）
    """
    ca_cert = CertificateService.get_ca_certificate()
    if not ca_cert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="CA证书不存在，请先生成CA证书"
        )
    return Response(
        content=ca_cert,
        media_type="application/x-pem-file",
        headers={"Content-Disposition": "attachment; filename=ca.crt"}
    )


@router.post("/server/generate", response_model=ServerCertificateResponse)
async def generate_server_certificate(
    cert_req: ServerCertificateRequest,
    current_user: User = Depends(get_current_admin_user)
) -> ServerCertificateResponse:
    """
    生成服务器证书（仅管理员）
    """
    try:
        server_key, server_cert = CertificateService.generate_server_certificate(
            common_name=cert_req.common_name,
            alt_names=cert_req.alt_names,
            validity_days=cert_req.validity_days
        )
        return ServerCertificateResponse(
            server_key=server_key,
            server_cert=server_cert,
            message="服务器证书已成功生成"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"生成服务器证书失败: {str(e)}"
        )


@router.post("/client/generate/{device_id}", response_model=ClientCertificateResponse)
async def generate_client_certificate(
    device_id: str,
    cert_req: ClientCertificateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
) -> ClientCertificateResponse:
    """
    为设备生成客户端证书
    """
    # 检查设备是否存在
    device_service = DeviceService(db)
    device = await device_service.get_by_device_id(device_id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="设备不存在"
        )
    
    try:
        # 生成证书
        client_key, client_cert, serial_number = CertificateService.generate_client_certificate(
            device_id=device.device_id,
            common_name=cert_req.common_name,
            validity_days=cert_req.validity_days
        )
        
        # 获取CA证书
        ca_cert = CertificateService.get_ca_certificate()
        if not ca_cert:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="CA证书不存在，请先生成CA证书"
            )
        
        # 保存证书到数据库
        from datetime import datetime, timedelta
        cert_in = DeviceCertificateCreate(
            certificate=client_cert,
            private_key=client_key,
            certificate_type="client",
            serial_number=serial_number,
            issued_at=datetime.utcnow(),
            expires_at=datetime.utcnow() + timedelta(days=cert_req.validity_days)
        )
        
        await device_service.add_certificate(device, cert_in)
        
        return ClientCertificateResponse(
            client_key=client_key,
            client_cert=client_cert,
            ca_cert=ca_cert,
            serial_number=serial_number,
            message="客户端证书已成功生成并保存"
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"生成客户端证书失败: {str(e)}"
        )


@router.post("/verify", response_model=CertificateVerificationResponse)
async def verify_certificate(
    cert_req: CertificateVerificationRequest,
    current_user: User = Depends(get_current_active_user)
) -> CertificateVerificationResponse:
    """
    验证证书有效性
    """
    try:
        is_valid, error_message = CertificateService.verify_certificate(cert_req.certificate)
        return CertificateVerificationResponse(
            is_valid=is_valid,
            error_message=error_message
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"验证证书失败: {str(e)}"
        )


@router.post("/revoke", response_model=CertificateRevokeResponse)
async def revoke_certificate(
    revoke_req: CertificateRevokeRequest,
    current_user: User = Depends(get_current_admin_user)
) -> CertificateRevokeResponse:
    """
    吊销证书（仅管理员）
    """
    try:
        success = CertificateService.revoke_certificate(
            serial_number=revoke_req.serial_number,
            reason=revoke_req.reason
        )
        if success:
            return CertificateRevokeResponse(
                success=True,
                message="证书已成功吊销"
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="吊销证书失败"
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"吊销证书失败: {str(e)}"
        )

