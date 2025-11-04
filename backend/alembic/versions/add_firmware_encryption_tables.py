"""add firmware encryption tables

Revision ID: add_firmware_encryption
Revises: add_server_certificates
Create Date: 2025-11-04 15:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_firmware_encryption'
down_revision = 'add_server_certificates'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 创建设备加密密钥表
    op.create_table(
        'device_encryption_keys',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, primary_key=True),
        sa.Column('device_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('key_encrypted', sa.Text(), nullable=False),
        sa.Column('key_hash', sa.String(64), nullable=False),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.ForeignKeyConstraint(['device_id'], ['devices.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
    )
    
    # 创建固件构建记录表
    op.create_table(
        'firmware_builds',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, primary_key=True),
        sa.Column('device_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('firmware_path', sa.String(512), nullable=False),
        sa.Column('firmware_hash', sa.String(64), nullable=False),
        sa.Column('firmware_size', sa.String(20), nullable=False),
        sa.Column('encrypted_firmware_path', sa.String(512), nullable=True),
        sa.Column('encrypted_firmware_hash', sa.String(64), nullable=True),
        sa.Column('build_type', sa.String(20), nullable=False, server_default='encrypted'),
        sa.Column('encryption_key_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('status', sa.String(20), nullable=False, server_default='pending'),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['device_id'], ['devices.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['encryption_key_id'], ['device_encryption_keys.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
    )
    
    # 创建索引
    op.create_index('ix_device_encryption_keys_device_id', 'device_encryption_keys', ['device_id'], unique=True)
    op.create_index('ix_firmware_builds_device_id', 'firmware_builds', ['device_id'])
    op.create_index('ix_firmware_builds_status', 'firmware_builds', ['status'])


def downgrade() -> None:
    # 删除索引
    op.drop_index('ix_firmware_builds_status', table_name='firmware_builds')
    op.drop_index('ix_firmware_builds_device_id', table_name='firmware_builds')
    op.drop_index('ix_device_encryption_keys_device_id', table_name='device_encryption_keys')
    
    # 删除表
    op.drop_table('firmware_builds')
    op.drop_table('device_encryption_keys')

