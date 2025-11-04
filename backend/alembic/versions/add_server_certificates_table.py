"""add server_certificates table

Revision ID: add_server_certificates
Revises: add_device_templates_table
Create Date: 2025-11-04 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_server_certificates'
down_revision = 'add_device_templates'  # 基于最新的迁移
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 创建server_certificates表
    op.create_table(
        'server_certificates',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, primary_key=True),
        sa.Column('certificate', sa.String(), nullable=False),
        sa.Column('private_key', sa.String(), nullable=False),
        sa.Column('common_name', sa.String(255), nullable=False),
        sa.Column('serial_number', sa.String(100), nullable=False, unique=True),
        sa.Column('issued_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('revoked_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('revoke_reason', sa.String(100), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
    )
    
    # 创建索引
    op.create_index('ix_server_certificates_serial_number', 'server_certificates', ['serial_number'], unique=True)
    op.create_index('ix_server_certificates_is_active', 'server_certificates', ['is_active'])
    op.create_index('ix_server_certificates_created_at', 'server_certificates', ['created_at'])


def downgrade() -> None:
    # 删除索引
    op.drop_index('ix_server_certificates_created_at', table_name='server_certificates')
    op.drop_index('ix_server_certificates_is_active', table_name='server_certificates')
    op.drop_index('ix_server_certificates_serial_number', table_name='server_certificates')
    
    # 删除表
    op.drop_table('server_certificates')

