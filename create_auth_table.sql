CREATE TABLE IF NOT EXISTS auth_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR UNIQUE NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    hashed_password VARCHAR NOT NULL,
    full_name VARCHAR,
    is_active BOOLEAN DEFAULT true,
    is_superuser BOOLEAN DEFAULT false,
    org_id INTEGER DEFAULT 1,
    role VARCHAR DEFAULT 'user',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_auth_users_username ON auth_users(username);
CREATE INDEX IF NOT EXISTS ix_auth_users_email ON auth_users(email);
CREATE INDEX IF NOT EXISTS ix_auth_users_org_id ON auth_users(org_id);

INSERT INTO auth_users (username, email, hashed_password, is_active, is_superuser, role)
VALUES ('admin', 'admin@vetrai.local', '$2b$12$Yq.5Eh3vb/PZsqZRPWxgj.8XVz1EoR3MKPfKKKkKKKkKKKkKKKkKKe', true, true, 'super_admin')
ON CONFLICT DO NOTHING;

SELECT 'auth_users table setup complete' AS status;
