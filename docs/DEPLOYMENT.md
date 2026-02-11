# Vetrai Documentation Deployment Guide

## Overview
The Vetrai documentation is built with [Docusaurus](https://docusaurus.io/) and can be deployed to multiple platforms.

---

## Option 1: GitHub Pages (Recommended)

### Automatic Deployment
The docs automatically deploy to GitHub Pages when changes are pushed to the `main` branch in the `docs/` folder.

**Workflow:** `.github/workflows/deploy_gh-pages.yml`

### Setup Steps
1. **Enable GitHub Pages** in your repository:
   - Go to `Settings > Pages`
   - Source: `Deploy from a branch`
   - Branch: `gh-pages` / `root`

2. **Configure Custom Domain** (for docs.vetrai.org):
   - In `Settings > Pages`, add custom domain: `docs.vetrai.org`
   - Add a `CNAME` file in `docs/static/` with content: `docs.vetrai.org`

3. **DNS Configuration** at your domain registrar:
   ```
   Type: CNAME
   Name: docs
   Value: vetrai.github.io
   ```

### Manual Deployment
```bash
cd docs
npm install
npm run build
npm run deploy
```

---

## Option 2: Vercel

### Setup Steps
1. Import repository at [vercel.com](https://vercel.com)
2. Configure build settings:
   - **Framework Preset:** Docusaurus
   - **Root Directory:** `docs`
   - **Build Command:** `npm run build`
   - **Output Directory:** `build`

3. Add custom domain: `docs.vetrai.org`

### DNS Configuration
```
Type: CNAME
Name: docs
Value: cname.vercel-dns.com
```

---

## Option 3: Netlify

### Setup Steps
1. Connect repository at [netlify.com](https://app.netlify.com)
2. Configure build settings:
   - **Base directory:** `docs`
   - **Build command:** `npm run build`
   - **Publish directory:** `docs/build`

3. Add custom domain: `docs.vetrai.org`

### DNS Configuration
```
Type: CNAME
Name: docs
Value: [your-site-name].netlify.app
```

---

## Local Development

```bash
# Navigate to docs folder
cd docs

# Install dependencies
npm install

# Start development server
npm run start

# Build for production
npm run build

# Serve production build locally
npm run serve
```

---

## Documentation Structure

```
docs/
├── docs/                 # Markdown documentation files
│   ├── get-started/     # Getting started guides
│   ├── concepts/        # Core concepts
│   ├── components/      # Component reference
│   ├── deployment/      # Deployment guides
│   └── api/             # API documentation
├── src/                  # Custom React components
├── static/              # Static assets (images, etc.)
├── docusaurus.config.js # Docusaurus configuration
├── sidebars.js          # Sidebar navigation
└── package.json         # Dependencies
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `BASE_URL` | Base URL path (default: `/`) |
| `SEGMENT_PUBLIC_WRITE_KEY` | Analytics tracking key |

---

## Custom Domain Setup Summary

### For docs.vetrai.org:

1. **GitHub Pages:**
   - Add `CNAME` file with `docs.vetrai.org`
   - DNS: `docs` CNAME → `vetrai.github.io`

2. **Vercel:**
   - Add domain in project settings
   - DNS: `docs` CNAME → `cname.vercel-dns.com`

3. **Netlify:**
   - Add domain in project settings
   - DNS: `docs` CNAME → `[site].netlify.app`

---

Created: 2026-01-06
