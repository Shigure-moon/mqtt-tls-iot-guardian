"""add device_templates table

Revision ID: add_device_templates
Revises: 1234567890ab
Create Date: 2024-01-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_device_templates'
down_revision = '1234567890ab'
branch_labels = None
depends_on = None


def upgrade():
    # 创建设备模板表
    op.create_table(
        'device_templates',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('device_type', sa.String(length=50), nullable=False),
        sa.Column('description', sa.String(length=500), nullable=True),
        sa.Column('template_code', sa.Text(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name')
    )
    
    # 创建索引
    op.create_index('ix_device_templates_name', 'device_templates', ['name'])
    op.create_index('ix_device_templates_device_type', 'device_templates', ['device_type'])


def downgrade():
    # 删除索引
    op.drop_index('ix_device_templates_device_type', table_name='device_templates')
    op.drop_index('ix_device_templates_name', table_name='device_templates')
    
    # 删除表
    op.drop_table('device_templates')

