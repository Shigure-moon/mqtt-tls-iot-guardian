"""add ota_update_tasks table

Revision ID: add_ota_update_tasks
Revises: add_firmware_encryption_tables
Create Date: 2025-01-04 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_ota_update_tasks'
down_revision = 'add_firmware_encryption'  # 使用实际的revision ID
branch_labels = None
depends_on = None


def upgrade():
    # 创建OTA更新任务表
    op.create_table(
        'ota_update_tasks',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('device_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('firmware_build_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('firmware_url', sa.String(512), nullable=False),
        sa.Column('firmware_version', sa.String(50), nullable=True),
        sa.Column('firmware_hash', sa.String(64), nullable=True),
        sa.Column('status', sa.String(20), server_default='pending', nullable=False),
        sa.Column('progress', sa.String(20), server_default='0%', nullable=False),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['device_id'], ['devices.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['firmware_build_id'], ['firmware_builds.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
    )
    
    # 创建索引
    op.create_index('ix_ota_update_tasks_device_id', 'ota_update_tasks', ['device_id'])
    op.create_index('ix_ota_update_tasks_status', 'ota_update_tasks', ['status'])
    op.create_index('ix_ota_update_tasks_created_at', 'ota_update_tasks', ['created_at'])


def downgrade():
    # 删除索引
    op.drop_index('ix_ota_update_tasks_created_at', table_name='ota_update_tasks')
    op.drop_index('ix_ota_update_tasks_status', table_name='ota_update_tasks')
    op.drop_index('ix_ota_update_tasks_device_id', table_name='ota_update_tasks')
    
    # 删除表
    op.drop_table('ota_update_tasks')

