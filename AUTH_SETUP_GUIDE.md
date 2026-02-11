# Vetrai JWT Authentication Setup Guide

This guide covers the complete JWT-based authentication system that protects the Langflow application.

## 🎯 Overview

The authentication system provides:
- ✅ **JWT-based login** with username/password
- ✅ **Token refresh** for long-lived sessions
- ✅ **User context** (user_id, org_id, role) throughout the app
- ✅ **Automatic session restoration** on page refresh
- ✅ **Role-based access control (RBAC)** ready for implementation
- ✅ **Secure password hashing** with bcrypt

---

## 📋 Prerequisites

- Python 3.10+
- Node.js 18+
- PostgreSQL or SQLite (for development)

---

## 🚀 Installation & Setup

### 1. Backend Setup

#### Install Dependencies
```bash
cd src/backend/base
pip install PyJWT passlib[bcrypt] bcrypt sqlalchemy
```

#### Create Database Tables
```bash
# Run Alembic migrations to create auth_users table
cd vetrai
alembic upgrade head
```

This creates the `auth_users` table with the following schema:
```sql
CREATE TABLE auth_users (
    id INTEGER PRIMARY KEY,
    username VARCHAR UNIQUE NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    hashed_password VARCHAR NOT NULL,
    full_name VARCHAR,
    is_active BOOLEAN DEFAULT TRUE,
    is_superuser BOOLEAN DEFAULT FALSE,
    org_id INTEGER DEFAULT 1,
    role VARCHAR DEFAULT 'user',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### Initialize Default Admin User
The system automatically creates a default admin user on first run:
```
Username: admin
Password: admin123
Role: super_admin
```

⚠️ **Important**: Change this password immediately in production!

#### Environment Variables
Create a `.env` file in the backend directory:
```bash
# JWT Configuration
SECRET_KEY=your-super-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Database
DATABASE_URL=postgresql://user:password@localhost/vetrai
# or for SQLite:
DATABASE_URL=sqlite:///./test.db
```

### 2. Frontend Setup

#### Install Dependencies
```bash
cd src/frontend
npm install zustand
```

#### Configure API URL
Update your `.env` or environment variables:
```bash
REACT_APP_API_URL=http://localhost:7860
```

---

## 📡 API Endpoints

### 1. Login
**Endpoint:** `POST /api/auth/login`

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@vetrai.local",
    "full_name": "Admin User",
    "is_active": true,
    "is_superuser": true,
    "org_id": 1,
    "role": "super_admin",
    "created_at": "2026-02-11T00:00:00"
  }
}
```

### 2. Get Current User
**Endpoint:** `GET /api/auth/me`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:** (Same user object as login)

### 3. Refresh Token
**Endpoint:** `POST /api/auth/refresh`

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 4. Logout
**Endpoint:** `POST /api/auth/logout`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

---

## 🎨 Frontend Integration

### 1. Using the Auth Store

```typescript
import useAuthStore from "@/stores/authStore";

function MyComponent() {
  const { user, isAuthenticated, accessToken, logout } = useAuthStore();
  
  if (!isAuthenticated) {
    return <div>Please log in</div>;
  }
  
  return (
    <div>
      <p>Welcome, {user?.full_name}!</p>
      <p>Role: {user?.role}</p>
      <button onClick={() => logout()}>Logout</button>
    </div>
  );
}
```

### 2. Using the Login Hook

```typescript
import { useJWTLogin } from "@/hooks/useJWTLogin";

function LoginForm() {
  const { login, isLoading, error } = useJWTLogin();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await login(username, password);
    } catch (err) {
      console.error("Login failed:", err);
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        placeholder="Username"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      <button disabled={isLoading}>
        {isLoading ? "Signing in..." : "Sign In"}
      </button>
      {error && <div className="error">{error}</div>}
    </form>
  );
}
```

### 3. Adding JWT to API Calls

Update your API client to include the JWT token:

```typescript
import useAuthStore from "@/stores/authStore";

export async function apiCall(endpoint: string, options = {}) {
  const { accessToken } = useAuthStore.getState();
  
  const headers = {
    "Content-Type": "application/json",
    ...options.headers,
  };
  
  if (accessToken) {
    headers["Authorization"] = `Bearer ${accessToken}`;
  }
  
  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });
  
  if (response.status === 401) {
    // Token expired or invalid
    useAuthStore.getState().logout();
    window.location.href = "/login";
  }
  
  return response.json();
}
```

---

## 🔐 Security Best Practices

### 1. Token Storage
- ✅ Access tokens stored in memory (or localStorage with secure practices)
- ✅ Refresh tokens in httpOnly cookies (if backend sends them)
- ❌ Never store sensitive data in localStorage (if possible)

### 2. CORS Configuration
Update your FastAPI app to allow login requests:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 3. HTTPS in Production
- ✅ Always use HTTPS
- ✅ Set `secure=True` on cookies
- ✅ Set `samesite="Strict"` on cookies

### 4. Secret Key Management
```python
# DO NOT hardcode in production!
import secrets
SECRET_KEY = secrets.token_urlsafe(32)

# Use environment variables:
SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production")
```

---

## 🧪 Testing

### 1. Manual Testing with cURL

```bash
# Login
curl -X POST http://localhost:7860/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Get current user
curl -X GET http://localhost:7860/api/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Refresh token
curl -X POST http://localhost:7860/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"YOUR_REFRESH_TOKEN"}'

# Logout
curl -X POST http://localhost:7860/api/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 2. Create Test Users
```python
# From Python shell
from vetrai.auth.service import AuthService, UserService
from sqlalchemy.orm import Session
from vetrai.services.deps import session_scope

async def create_test_user():
    async with session_scope() as session:
        user = UserService.create_user(
            session,
            username="testuser",
            email="test@example.com",
            password="testpass123",
            full_name="Test User",
            org_id=1,
            role="user"
        )
        session.add(user)
        session.commit()
```

---

## 📊 Token Structure

### Access Token Payload
```json
{
  "user_id": 1,
  "username": "admin",
  "email": "admin@vetrai.local",
  "org_id": 1,
  "role": "super_admin",
  "exp": 1739284800,
  "type": "access"
}
```

### Refresh Token Payload
```json
{
  "user_id": 1,
  "exp": 1739889600,
  "type": "refresh"
}
```

---

## 🐛 Troubleshooting

### Issue: "Repository not found" during migration
**Solution:**
```bash
# Ensure database exists and is accessible
alembic current  # Check current revision
alembic upgrade head  # Run pending migrations
```

### Issue: "Invalid Token" error
**Solutions:**
- Check if SECRET_KEY matches between requests
- Verify token hasn't expired
- Ensure proper JWT format: `Bearer <token>`

### Issue: CORS errors
**Solution:**
Ensure CORS middleware is configured in main.py:
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production!
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Issue: Tokens not persisting after refresh
**Solution:**
Ensure localStorage is enabled and updateAuthStore is correctly saving tokens:
```typescript
useAuthStore.getState().setAuthTokens(access, refresh, user);
```

---

## 📨 Next Steps

1. **Add RBAC Checks**: Implement role-based UI element visibility
2. **Multi-Tenant Support**: Use `org_id` from token for data scoping
3. **Audit Logging**: Log all authentication events
4. **Email Verification**: Add email confirmation on signup
5. **Two-Factor Authentication**: Add 2FA for admin users
6. **SSO Integration**: Add OAuth2/SAML support

---

## 📚 Related Files

- Backend Auth Module: `src/backend/base/vetrai/auth/`
- Frontend Auth Store: `src/frontend/src/stores/authStore.ts`
- Login Hook: `src/frontend/src/hooks/useJWTLogin.ts`
- API Client: `src/frontend/src/utils/authAPIClient.ts`
- Protected Route: `src/frontend/src/components/authorization/authGuard/index.tsx`
- Database Migration: `src/backend/base/vetrai/alembic/versions/a001_add_auth_users_table.py`

---

**Last Updated:** February 11, 2026  
**Version:** 1.0
