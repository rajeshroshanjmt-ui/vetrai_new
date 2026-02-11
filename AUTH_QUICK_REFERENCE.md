# Vetrai Authentication - Quick Reference

## 🚀 Quick Start (5 minutes)

### 1. Run Database Migration
```bash
cd src/backend/base/vetrai
alembic upgrade head
```

### 2. Start Backend
```bash
cd src/backend/base
python -m uvicorn vetrai.main:create_app --factory --reload
```

### 3. Start Frontend
```bash
cd src/frontend
npm run dev
```

### 4. Login
**URL:** http://localhost:5173/login  
**Username:** `admin`  
**Password:** `admin123`

---

## 🔑 API Quick Reference

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/auth/login` | Authenticate with username/password |
| GET | `/api/auth/me` | Get current user (requires Bearer token) |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Logout user |

---

## 💾 Frontend Usage

### Get Current User
```typescript
import useAuthStore from "@/stores/authStore";

const { user, isAuthenticated } = useAuthStore();
console.log(user?.username);  // "admin"
console.log(user?.role);      // "super_admin"
```

### Logout
```typescript
useAuthStore.getState().logout();
```

### Login (in component)
```typescript
import { useJWTLogin } from "@/hooks/useJWTLogin";

const { login, isLoading, error } = useJWTLogin();
await login("admin", "admin123");
```

---

## 🛡️ How It Works

```
User (Browser)
    ↓
Login with username/password
    ↓
POST /api/auth/login
    ↓
Backend: Verify password, generate JWT tokens
    ↓
Response: access_token + refresh_token + user data
    ↓
Frontend: Store in Zustand + localStorage
    ↓
Protected routes check isAuthenticated
    ↓
API calls include: Authorization: Bearer <token>
    ↓
Automatic token refresh every 30 minutes
    ↓
User accesses Langflow app with full context
```

---

## 📁 File Structure

```
src/backend/base/vetrai/auth/
├── __init__.py           # Module exports
├── models.py             # SQLAlchemy + Pydantic models
├── service.py            # AuthService + UserService
└── routes.py             # FastAPI endpoints

src/frontend/src/
├── stores/authStore.ts                    # Zustand store
├── hooks/useJWTLogin.ts                   # Login hook
├── utils/authAPIClient.ts                 # API client
├── components/authorization/authGuard/    # Protected routes
└── pages/LoginPage/index.tsx               # Login UI

src/backend/base/vetrai/alembic/versions/
└── a001_add_auth_users_table.py           # Database migration
```

---

## 🔒 Token Lifespan

| Token | Lifespan | Refresh |
|-------|----------|---------|
| Access | 30 min | Auto-refresh every 25 min |
| Refresh | 7 days | Provided on each refresh |

---

## ✅ Checklist Before Production

- [ ] Change default admin password
- [ ] Update SECRET_KEY in environment
- [ ] Configure HTTPS
- [ ] Set up email verification
- [ ] Enable RBAC checks
- [ ] Add rate limiting to `/api/auth/login`
- [ ] Configure CORS properly
- [ ] Set up audit logging
- [ ] Test token refresh flow
- [ ] Document custom user fields

---

## 🐛 Quick Debugging

### Check if backend auth is working
```bash
curl -X POST http://localhost:7860/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Check if frontend can reach backend
```javascript
// In browser console
fetch('http://localhost:7860/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'admin', password: 'admin123' })
}).then(r => r.json()).then(console.log);
```

### Check stored tokens
```javascript
// In browser console
localStorage.getItem('VETRAI_ACCESS_TOKEN');
localStorage.getItem('VETRAI_REFRESH_TOKEN');
```

### Clear auth and logout
```javascript
// In browser console
import useAuthStore from "@/stores/authStore";
useAuthStore.getState().logout();
```

---

## 🔗 Related Documentation

- [Full Setup Guide](./AUTH_SETUP_GUIDE.md)
- [RBAC Implementation](../docs/RBAC_GUIDE.md) *(Coming soon)*
- [Multi-Tenant Setup](../docs/MULTI_TENANT_GUIDE.md) *(Coming soon)*

---

**Last Updated:** February 11, 2026
