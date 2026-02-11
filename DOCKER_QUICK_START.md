# 🐳 Docker Compose Quick Start

## One-Minute Setup

```bash
# 1. Clone
git clone https://github.com/rajeshroshanjmt-ui/vetrai_new.git
cd vetrai_new

# 2. Setup
cp .env.example .env

# 3. Start
docker-compose up -d

# 4. Wait ~30 seconds for services to start, then visit:
open http://localhost:3000

# 5. Login
Username: admin
Password: admin123
```

## Common Commands

```bash
# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Database shell
docker-compose exec postgres psql -U vetrai -d vetrai

# Backup database
docker-compose exec postgres pg_dump -U vetrai vetrai > backup.sql

# See all services
docker-compose ps

# Monitor resources
docker stats
```

## Important for Production

```bash
# 1. Generate strong JWT secret
python -c "import secrets; print(secrets.token_urlsafe(32))"

# 2. Update .env with:
SECRET_KEY=<generated-above>

# 3. Change password
sed -i 's/admin123/strong-password/g' .env

# 4. Use Makefile for easier management
make -f Makefile.docker help
```

## Troubleshooting

- **Can't access http://localhost:3000?** - Wait 30 seconds for containers to fully start
- **"Port already in use"?** - Change ports in .env or kill process using `lsof -i :3000`
- **Database not connecting?** - Check logs: `docker-compose logs postgres`
- **Auth failing?** - Verify SECRET_KEY is set in .env

## Full Documentation

- [Complete Docker Setup Guide](./DOCKER_SETUP_GUIDE.md)
- [Authentication Guide](./AUTH_SETUP_GUIDE.md)
- [Quick Reference](./AUTH_QUICK_REFERENCE.md)

---

**Estimated time to fully functional system: 3-5 minutes**
