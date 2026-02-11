"""Authentication models for user login and session management."""
from datetime import datetime
from sqlalchemy import Column, DateTime, String, Integer, Boolean
from sqlalchemy.orm import declarative_base
from pydantic import BaseModel, Field

Base = declarative_base()


class UserDB(Base):
    """Database model for users."""
    __tablename__ = "auth_users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    org_id = Column(Integer, default=1)  # Default org
    role = Column(String, default="user")  # user, org_admin, super_admin
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class UserSchema(BaseModel):
    """Pydantic model for user responses."""
    id: int
    username: str
    email: str
    full_name: str | None
    is_active: bool
    is_superuser: bool
    org_id: int
    role: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    """Login request model."""
    username: str = Field(..., min_length=3)
    password: str = Field(..., min_length=6)


class LoginResponse(BaseModel):
    """Login response with tokens."""
    access_token: str
    refresh_token: str
    user: UserSchema


class TokenData(BaseModel):
    """JWT token payload."""
    user_id: int
    username: str
    email: str
    org_id: int
    role: str
    exp: int  # expiration timestamp


class RefreshTokenRequest(BaseModel):
    """Refresh token request."""
    refresh_token: str
