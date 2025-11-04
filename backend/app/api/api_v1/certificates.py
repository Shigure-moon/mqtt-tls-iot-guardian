"""
证书管理API端点
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.api_v1.auth import get_current_active_user, get_current_admin_user, get_current_super_admin_user
from app.core.database import get_db
from app.schemas.certificate import (
    CACertificateResponse,
    ServerCertificateRequest,
    ServerCertificateResponse,
    ServerCertificateInfo,
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


@router.get("/server", response_model=ServerCertificateInfo)
async def get_server_certificate(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> ServerCertificateInfo:
    """
    获取服务器证书（仅超级管理员）
    """
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        from app.models.certificate import ServerCertificate
        from sqlalchemy import select
        from app.core.encryption import decrypt_certificate_data
        
        # 获取最新的激活的服务器证书
        # 使用text查询避免relationship问题
        from sqlalchemy import text
        result = await db.execute(
            text("""
                SELECT id, certificate, private_key, common_name, serial_number, 
                       issued_at, expires_at, is_active, created_at, updated_at
                FROM server_certificates
                WHERE is_active = true
                ORDER BY created_at DESC
                LIMIT 1
            """)
        )
        row = result.fetchone()
        
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="服务器证书不存在，请先生成服务器证书"
            )
        
        # 解密证书数据
        try:
            cert_dict = {
                'id': str(row[0]),  # id
                'certificate': decrypt_certificate_data(row[1]),  # certificate
                'private_key': decrypt_certificate_data(row[2]),  # private_key
                'common_name': row[3],  # common_name
                'serial_number': row[4],  # serial_number
                'issued_at': row[5],  # issued_at
                'expires_at': row[6],  # expires_at
                'is_active': row[7],  # is_active
                'created_at': row[8],  # created_at
                'updated_at': row[9],  # updated_at
            }
            return ServerCertificateInfo(**cert_dict)
        except Exception as e:
            logger.error(f"解密证书数据失败: {e}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"解密证书数据失败: {str(e)}"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取服务器证书失败: {e}", exc_info=True)
        # 检查是否是表不存在
        error_msg = str(e).lower()
        if 'does not exist' in error_msg or 'relation' in error_msg:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="服务器证书表不存在，请先运行数据库迁移: alembic upgrade head"
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取服务器证书失败: {str(e)}"
        )


@router.post("/server/generate", response_model=ServerCertificateResponse)
async def generate_server_certificate(
    cert_req: ServerCertificateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_super_admin_user)
) -> ServerCertificateResponse:
    """
    生成服务器证书（仅超级管理员）
    生成后自动保存到数据库
    """
    import logging
    from datetime import datetime, timedelta
    from app.models.certificate import ServerCertificate
    from sqlalchemy import select
    from app.core.encryption import encrypt_certificate_data
    from cryptography import x509
    
    logger = logging.getLogger(__name__)
    
    try:
        # 检查CA证书是否存在
        ca_cert = CertificateService.get_ca_certificate()
        if not ca_cert:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="CA证书不存在，请先生成CA证书"
            )
        
        # 生成服务器证书
        server_key, server_cert = CertificateService.generate_server_certificate(
            common_name=cert_req.common_name,
            alt_names=cert_req.alt_names,
            validity_days=cert_req.validity_days
        )
        
        # 解析证书获取序列号
        from cryptography.hazmat.backends import default_backend
        cert_obj = x509.load_pem_x509_certificate(
            server_cert.encode('utf-8'),
            default_backend()
        )
        serial_number = str(cert_obj.serial_number)
        
        # 将旧证书标记为非激活
        from sqlalchemy import update
        stmt = (
            update(ServerCertificate)
            .where(ServerCertificate.is_active == True)
            .values(is_active=False)
        )
        await db.execute(stmt)
        await db.commit()
        
        # 保存新证书到数据库（加密存储）
        issued_at = datetime.utcnow()
        expires_at = issued_at + timedelta(days=cert_req.validity_days)
        
        new_cert = ServerCertificate(
            certificate=encrypt_certificate_data(server_cert),
            private_key=encrypt_certificate_data(server_key),
            common_name=cert_req.common_name,
            serial_number=serial_number,
            issued_at=issued_at,
            expires_at=expires_at,
            is_active=True,
            created_by=current_user.id
        )
        db.add(new_cert)
        await db.commit()
        await db.refresh(new_cert)
        
        return ServerCertificateResponse(
            server_key=server_key,
            server_cert=server_cert,
            message="服务器证书已成功生成并保存"
        )
    except HTTPException:
        raise
    except ValueError as e:
        # CA证书相关错误
        logger.error(f"生成服务器证书失败（CA证书问题）: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        await db.rollback()
        logger.error(f"生成服务器证书失败: {e}", exc_info=True)
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
    
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        # 检查CA证书是否存在
        ca_cert = CertificateService.get_ca_certificate()
        if not ca_cert:
            logger.error("CA证书不存在")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="CA证书不存在，请先生成CA证书"
            )
        
        logger.info(f"为设备 {device_id} 生成客户端证书，CN: {cert_req.common_name}")
        
        # 生成证书（如果序列号冲突，最多重试3次）
        max_retries = 3
        client_key = None
        client_cert = None
        serial_number = None
        
        for attempt in range(max_retries):
            try:
                client_key, client_cert, serial_number = CertificateService.generate_client_certificate(
                    device_id=device.device_id,
                    common_name=cert_req.common_name,
                    validity_days=cert_req.validity_days
                )
                logger.info(f"证书生成成功，序列号: {serial_number}")
                break
            except Exception as e:
                logger.error(f"证书生成失败（尝试 {attempt + 1}/{max_retries}）: {e}", exc_info=True)
                if attempt == max_retries - 1:
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail=f"证书生成失败: {str(e)}"
                    )
        
        # 保存证书到数据库（DeviceService会自动加密）
        # 如果序列号冲突，重试生成证书
        max_save_retries = 3
        for attempt in range(max_save_retries):
            try:
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
                logger.info(f"证书已保存到数据库，设备ID: {device_id}, 序列号: {serial_number}")
                break
            except ValueError as e:
                # 序列号冲突，重新生成证书
                if attempt < max_save_retries - 1:
                    logger.warning(f"序列号冲突，重新生成证书（尝试 {attempt + 1}/{max_save_retries}）: {e}")
                    try:
                        client_key, client_cert, serial_number = CertificateService.generate_client_certificate(
                            device_id=device.device_id,
                            common_name=cert_req.common_name,
                            validity_days=cert_req.validity_days
                        )
                        logger.info(f"重新生成证书成功，新序列号: {serial_number}")
                        continue
                    except Exception as gen_error:
                        logger.error(f"重新生成证书失败: {gen_error}", exc_info=True)
                        raise HTTPException(
                            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"重新生成证书失败: {str(gen_error)}"
                        )
                else:
                    logger.error(f"保存证书到数据库失败（尝试 {attempt + 1}/{max_save_retries}）: {e}", exc_info=True)
                    raise HTTPException(
                        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                        detail=f"保存证书到数据库失败: {str(e)}"
                    )
            except Exception as e:
                logger.error(f"保存证书到数据库失败: {e}", exc_info=True)
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"保存证书到数据库失败: {str(e)}"
                )
        
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
        logger.error(f"生成客户端证书失败: {e}", exc_info=True)
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

