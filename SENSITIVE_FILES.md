# Sensitive Files Security Guide

## Overview
This document identifies all files in the MTProto proxy project that contain sensitive information and explains how they are protected.

## 🔒 CRITICAL SENSITIVE FILES

### Environment Configuration Files
These files contain production secrets, API keys, and configuration data:

- **`.env`** - Main environment configuration (NEVER commit)
- **`.env.production`** - Production-specific configuration (NEVER commit)
- **`.env.*`** - Any environment-specific files (NEVER commit)

**Contains:**
- MTProto proxy secret keys
- Server IP addresses and domains
- Port configurations
- Authentication tokens
- Database credentials (if any)

### Test Reports and Logs
These files may contain connection data and system information:

- **`test-report-*.txt`** - Test execution reports (NEVER commit)
- **`*.log`** - Application logs (NEVER commit)
- **`logs/`** - Log directory (NEVER commit)

**May contain:**
- Connection attempts and IP addresses
- Error messages with system paths
- Performance metrics
- Debug information

## 🛡️ PROTECTION MEASURES

### Git Ignore Protection
All sensitive files are protected by `.gitignore` patterns:

```gitignore
# Environment files (SENSITIVE)
.env
.env.*
.env.production

# Logs and reports (SENSITIVE)
*.log
test-report-*.txt
logs/

# Certificates and secrets (SENSITIVE)
*.pem
*.key
*.crt
*secret*
*password*
*token*
```

### File Permissions
Ensure sensitive files have restricted permissions:

```bash
# Set restrictive permissions on environment files
chmod 600 .env*

# Set restrictive permissions on log files
chmod 600 *.log
```

### Backup Security
When creating backups, exclude sensitive files:

```bash
# Safe backup command
tar --exclude='.env*' --exclude='*.log' --exclude='test-report-*' -czf backup.tar.gz .
```

## ✅ SAFE TO COMMIT FILES

These files are safe to include in version control:

- **`.env.example`** - Template with placeholder values
- **`README.md`** - Documentation
- **`SECURITY.md`** - Security guidelines
- **`docker-compose.yml`** - Docker configuration (no secrets)
- **`Makefile`** - Build and management commands
- **`scripts/*.sh`** - Shell scripts (no hardcoded secrets)

## 🚨 EMERGENCY PROCEDURES

### If Sensitive File Was Committed
1. **Immediately remove from git history:**
   ```bash
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch .env' --prune-empty --tag-name-filter cat -- --all
   ```

2. **Force push to remote (if necessary):**
   ```bash
   git push origin --force --all
   ```

3. **Regenerate all secrets:**
   ```bash
   ./scripts/generate-secret.sh --update-env
   ```

4. **Update production configuration**

### If Repository Was Compromised
1. **Rotate all secrets immediately**
2. **Change server access credentials**
3. **Review access logs**
4. **Update firewall rules if needed**

## 📋 SECURITY CHECKLIST

Before committing any changes:

- [ ] Run `git status` to check staged files
- [ ] Verify no `.env*` files are staged
- [ ] Verify no `*.log` files are staged
- [ ] Verify no `test-report-*` files are staged
- [ ] Check for any files containing secrets or passwords
- [ ] Review diff for any hardcoded sensitive values

## 🔍 REGULAR SECURITY AUDIT

Monthly security review:

1. **Check git history for sensitive data:**
   ```bash
   git log --all --full-history -- .env*
   ```

2. **Scan for hardcoded secrets:**
   ```bash
   grep -r "password\|secret\|key\|token" --exclude-dir=.git .
   ```

3. **Review file permissions:**
   ```bash
   find . -name ".env*" -exec ls -la {} \;
   ```

4. **Verify .gitignore effectiveness:**
   ```bash
   git check-ignore .env .env.production *.log
   ```

## 📞 SUPPORT

If you discover a security issue:
1. Do NOT commit the issue to git
2. Document the issue privately
3. Follow the emergency procedures above
4. Contact the system administrator

---

**Remember: When in doubt, don't commit. It's easier to add a file later than to remove it from git history.**
