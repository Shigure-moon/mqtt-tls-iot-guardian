"""add threat_source and threat_correlations

Revision ID: add_threat_source
Revises: add_template_version_field
Create Date: 2024-11-12 16:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_threat_source'
down_revision = 'add_template_version'
branch_labels = None
depends_on = None


def upgrade():
    # 添加threat_source字段到security_events表
    op.add_column('security_events', 
        sa.Column('threat_source', sa.String(length=50), nullable=True)
    )
    
    # 创建威胁事件关联表
    op.create_table(
        'threat_correlations',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('primary_event_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('correlated_event_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('correlation_type', sa.String(length=50), nullable=True),
        sa.Column('confidence_score', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.ForeignKeyConstraint(['primary_event_id'], ['security_events.id'], ),
        sa.ForeignKeyConstraint(['correlated_event_id'], ['security_events.id'], ),
    )
    
    # 创建索引
    op.create_index('idx_threat_correlations_primary', 'threat_correlations', ['primary_event_id'])
    op.create_index('idx_threat_correlations_correlated', 'threat_correlations', ['correlated_event_id'])


def downgrade():
    # 删除索引
    op.drop_index('idx_threat_correlations_correlated', table_name='threat_correlations')
    op.drop_index('idx_threat_correlations_primary', table_name='threat_correlations')
    
    # 删除威胁关联表
    op.drop_table('threat_correlations')
    
    # 删除threat_source字段
    op.drop_column('security_events', 'threat_source')

