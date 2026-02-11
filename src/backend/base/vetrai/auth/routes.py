"""Authentication API routes."""
from fastapi import APIRouter, HTTPException, Depends, Header, status
from sqlalchemy.orm import Session

from vetrai.auth.models import LoginRequest, LoginResponse, RefreshTokenRequest, UserSchema
from vetrai.auth.service import AuthService, UserService
from vetrai.services.deps import session_scope

router = APIRouter(prefix="/api/auth", tags=["auth"])


async def get_db() -> Session:
    """Get database session."""
    from vetrai.services.deps import session_scope
    async with session_scope() as session:
        yield session


@router.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest, session: Session = Depends(get_db)):
    """Login with username and password."""
    # Get user from database
    user = UserService.get_user_by_username(session, request.username)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )
    
    # Verify password
    if not AuthService.verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive"
        )
    
    # Create tokens
    access_token = AuthService.create_access_token(user)
    refresh_token = AuthService.create_refresh_token(user)
    
    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserSchema.from_orm(user)
    )


@router.post("/refresh")
async def refresh_token(request: RefreshTokenRequest, session: Session = Depends(get_db)):
    """Refresh access token using refresh token."""
    # Verify refresh token
    payload = AuthService.verify_refresh_token(request.refresh_token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
    
    # Get user
    user = UserService.get_user_by_id(session, payload["user_id"])
    
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    # Create new access token
    access_token = AuthService.create_access_token(user)
    
    return {
        "access_token": access_token,
        "refresh_token": request.refresh_token
    }


@router.get("/me", response_model=UserSchema)
async def get_current_user(
    authorization: str = Header(None),
    session: Session = Depends(get_db)
):
    """Get current authenticated user."""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization header"
        )
    
    # Extract token from "Bearer <token>"
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise ValueError()
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format"
        )
    
    # Verify token
    token_data = AuthService.verify_token(token)
    
    if not token_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    # Get user
    user = UserService.get_user_by_id(session, token_data.user_id)
    
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    return UserSchema.from_orm(user)


@router.post("/logout")
async def logout():
    """Logout user (client-side clears token)."""
    return {"message": "Logged out successfully"}
