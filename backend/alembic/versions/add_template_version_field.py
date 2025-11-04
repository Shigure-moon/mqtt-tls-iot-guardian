"""add version and required_libraries fields to device_templates

Revision ID: add_template_version
Revises: add_device_templates
Create Date: 2025-01-04 16:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_template_version'
down_revision = 'add_device_templates'
branch_labels = None
depends_on = None


def upgrade():
    # 添加版本字段
    op.add_column('device_templates', sa.Column('version', sa.String(length=20), nullable=False, server_default='v1'))
    
    # 添加所需库字段
    op.add_column('device_templates', sa.Column('required_libraries', sa.Text(), nullable=True))
    
    # 删除旧的唯一约束（name）
    op.drop_constraint('device_templates_name_key', 'device_templates', type_='unique')
    
    # 创建新的唯一约束（name + version）
    op.create_index('ix_device_templates_name_version', 'device_templates', ['name', 'version'], unique=True)
    
    # 创建版本索引
    op.create_index('ix_device_templates_version', 'device_templates', ['version'])


def downgrade():
    # 删除索引
    op.drop_index('ix_device_templates_version', table_name='device_templates')
    op.drop_index('ix_device_templates_name_version', table_name='device_templates')
    
    # 恢复旧的唯一约束
    op.create_unique_constraint('device_templates_name_key', 'device_templates', ['name'])
    
    # 删除字段
    op.drop_column('device_templates', 'required_libraries')
    op.drop_column('device_templates', 'version')

