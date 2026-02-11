"""Authentication service - handles JWT, passwords, and user validation."""
import os
from datetime import datetime, timedelta, timezone
from typing import Optional

import jwt
from passlib.context import CryptContext

from vetrai.auth.models import TokenData, UserDB, UserSchema

# Security settings
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    """Handle JWT token generation, validation, and password operations."""
    
    @staticmethod
    def hash_password(password: str) -> str:
        """Hash a password using bcrypt."""
        return pwd_context.hash(password)
    
    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify password against hash."""
        return pwd_context.verify(plain_password, hashed_password)
    
    @staticmethod
    def create_access_token(user: UserDB, expires_delta: Optional[timedelta] = None) -> str:
        """Create JWT access token."""
        if expires_delta is None:
            expires_delta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        expire = datetime.now(timezone.utc) + expires_delta
        
        payload = {
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "org_id": user.org_id,
            "role": user.role,
            "exp": int(expire.timestamp()),
            "type": "access"
        }
        
        encoded_jwt = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def create_refresh_token(user: UserDB) -> str:
        """Create JWT refresh token."""
        expires_delta = timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
        expire = datetime.now(timezone.utc) + expires_delta
        
        payload = {
            "user_id": user.id,
            "exp": int(expire.timestamp()),
            "type": "refresh"
        }
        
        encoded_jwt = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str) -> Optional[TokenData]:
        """Verify and decode JWT access token."""
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            
            if payload.get("type") != "access":
                return None
            
            return TokenData(
                user_id=payload["user_id"],
                username=payload["username"],
                email=payload["email"],
                org_id=payload["org_id"],
                role=payload["role"],
                exp=payload["exp"]
            )
        except jwt.ExpiredSignatureError:
            return None
        except jwt.JWTError:
            return None
    
    @staticmethod
    def verify_refresh_token(token: str) -> Optional[dict]:
        """Verify and decode JWT refresh token."""
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            
            if payload.get("type") != "refresh":
                return None
            
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.JWTError:
            return None


class UserService:
    """Handle user database operations."""
    
    @staticmethod
    def create_default_user(db_session):
        """Create default admin user if none exists."""
        from sqlalchemy import select
        
        # Check if any user exists
        existing = db_session.execute(select(UserDB)).first()
        if existing:
            return
        
        # Create default admin
        default_user = UserDB(
            username="admin",
            email="admin@vetrai.local",
            full_name="Admin User",
            hashed_password=AuthService.hash_password("admin123"),
            is_active=True,
            is_superuser=True,
            org_id=1,
            role="super_admin"
        )
        
        db_session.add(default_user)
        db_session.commit()
        db_session.refresh(default_user)
        return default_user
    
    @staticmethod
    def get_user_by_username(db_session, username: str) -> Optional[UserDB]:
        """Get user by username."""
        from sqlalchemy import select
        
        result = db_session.execute(
            select(UserDB).where(UserDB.username == username)
        ).first()
        return result[0] if result else None
    
    @staticmethod
    def get_user_by_id(db_session, user_id: int) -> Optional[UserDB]:
        """Get user by ID."""
        from sqlalchemy import select
        
        result = db_session.execute(
            select(UserDB).where(UserDB.id == user_id)
        ).first()
        return result[0] if result else None
