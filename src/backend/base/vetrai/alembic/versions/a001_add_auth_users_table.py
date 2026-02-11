"""Add auth_users table for JWT authentication

Revision ID: a001_add_auth_users_table
Revises: 
Create Date: 2026-02-11 00:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a001_add_auth_users_table"
down_revision: str | None = "260dbcc8b680"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Create auth_users table for JWT-based authentication."""
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    existing_tables = inspector.get_table_names()
    
    # Only create if table doesn't exist
    if "auth_users" not in existing_tables:
        op.create_table(
            "auth_users",
            sa.Column("id", sa.Integer, primary_key=True, index=True),
            sa.Column("username", sa.String, unique=True, nullable=False, index=True),
            sa.Column("email", sa.String, unique=True, nullable=False, index=True),
            sa.Column("hashed_password", sa.String, nullable=False),
            sa.Column("full_name", sa.String),
            sa.Column("is_active", sa.Boolean, default=True),
            sa.Column("is_superuser", sa.Boolean, default=False),
            sa.Column("org_id", sa.Integer, default=1),
            sa.Column("role", sa.String, default="user"),
            sa.Column("created_at", sa.DateTime, default=sa.func.now()),
            sa.Column("updated_at", sa.DateTime, default=sa.func.now(), onupdate=sa.func.now()),
        )
        
        # Create indices
        op.create_index("ix_auth_users_username", "auth_users", ["username"])
        op.create_index("ix_auth_users_email", "auth_users", ["email"])
        op.create_index("ix_auth_users_org_id", "auth_users", ["org_id"])


def downgrade() -> None:
    """Drop auth_users table."""
    op.drop_table("auth_users")
