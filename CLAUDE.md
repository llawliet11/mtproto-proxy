# MTProto Proxy Project - AI Agent Continuation Guide

## Claude Code Imports
This file imports additional documentation for comprehensive context:

See @README.md for project overview and setup instructions. For security guidelines and best practices, refer to @docs/SECURITY.md and @docs/SENSITIVE_FILES.md for sensitive files management.

Project architecture details are available in @docs/PROJECT_SUMMARY.md. For Docker-related troubleshooting, see @docs/DOCKER_BUILD_FIX.md and @docs/DOCKER_PORTS_EXPLAINED.md for ports configuration.

AI agent operational guidelines are defined in @.augment-guidelines.

## Project Context & History

This is a complete MTProto proxy implementation for Telegram, built from scratch based on research of current best practices in 2024. The project was created to provide a secure, production-ready proxy server using the `mtg` (Go-based) implementation.

### Original Request
User requested: "Research the internet, and build project for creating MTPROTO proxy for telegram. Also create .env file contains server, port, username, password etc. Do neccessary setup for me, always follow best practices"

### Research Findings
- **mtg** (9seconds/mtg) identified as the best Go-based implementation
- High performance, security-focused, actively maintained
- Supports TLS camouflage, statistics, and modern security features
- Better than Python implementations for production use

## Project Architecture

### Core Implementation
- **Base Technology**: mtg (Go-based MTProto proxy)
- **Deployment**: Docker + Manual installation options
- **Configuration**: Environment variable based (.env)
- **Management**: Shell scripts + Makefile
- **Security**: Hardened configuration with best practices

### Key Design Decisions
1. **mtg over alternatives**: Performance and security advantages
2. **Docker-first approach**: Easy deployment and isolation
3. **Environment-based config**: 12-factor app principles
4. **Comprehensive scripting**: Automation for all operations
5. **Security by default**: Hardened configurations out of the box

## Current Project State

### Completed Components ✅

#### Core Files
- `README.md` - Complete user documentation
- `.env` - Pre-configured with secure secret: `2e96222882f7c201b73dd8bd04262571`
- `.env.example` - Configuration template
- `docker-compose.yml` - Production Docker setup
- `Dockerfile` - Multi-stage optimized build
- `Makefile` - Management commands
- `.gitignore` - Proper exclusions

#### Scripts & Automation
- `setup.sh` - Interactive guided setup (333 lines)
- `install.sh` - Manual installation automation
- `start.sh` - Proxy lifecycle management
- `scripts/entrypoint.sh` - Docker container entrypoint
- `scripts/healthcheck.sh` - Health monitoring
- `scripts/generate-secret.sh` - Secure secret generation
- `scripts/monitor.sh` - Real-time monitoring & statistics
- `scripts/test-proxy.sh` - Comprehensive testing suite

#### Documentation
- `docs/SECURITY.md` - Complete security guide
- `docs/SENSITIVE_FILES.md` - Sensitive files management
- `docs/PROJECT_SUMMARY.md` - Detailed project overview
- `docs/DOCKER_BUILD_FIX.md` - Docker build troubleshooting
- `docs/DOCKER_PORTS_EXPLAINED.md` - Docker ports configuration
- `CLAUDE.md` - This continuation guide
- `.augment-guidelines` - AI agent guidelines

### Current Configuration
```env
MTG_SECRET=2e96222882f7c201b73dd8bd04262571  # Cryptographically secure
MTG_PORT=8443                                # Recommended secure port
SERVER_HOST=localhost                        # Change to actual domain/IP
MTG_WORKERS=2                               # Optimal for most setups
MTG_SECURE_ONLY=true                        # Security enabled
MTG_STATS_ENABLED=true                      # Monitoring enabled
MTG_STATS_PORT=3001                         # Statistics endpoint
```

### Testing Status
Last test run showed:
- ✅ Configuration validation passed
- ✅ Docker setup verified
- ✅ System resources adequate
- ❌ Proxy not running (expected - not started yet)
- ❌ Ports not accessible (expected - not started yet)

## File Structure & Relationships

```
mtproto-proxy/
├── Core Configuration
│   ├── .env                    # Active config with secure secret
│   ├── .env.example           # Template for new deployments
│   └── docker-compose.yml     # Production Docker setup
├── Build & Deployment
│   ├── Dockerfile             # Multi-stage optimized build
│   └── Makefile              # Management commands (help, start, stop, etc.)
├── Setup & Management
│   ├── setup.sh              # Interactive guided setup
│   ├── install.sh            # Manual installation
│   └── start.sh              # Proxy lifecycle management
├── Utility Scripts
│   ├── scripts/entrypoint.sh    # Docker container entrypoint
│   ├── scripts/healthcheck.sh   # Health monitoring
│   ├── scripts/generate-secret.sh # Secure secret generation
│   ├── scripts/monitor.sh       # Real-time monitoring
│   └── scripts/test-proxy.sh    # Testing suite
├── Documentation
│   ├── README.md             # User documentation (root level)
│   ├── CLAUDE.md            # This file (root level)
│   ├── .augment-guidelines  # AI agent guidelines (root level)
│   └── docs/                # Documentation folder
│       ├── SECURITY.md          # Security best practices
│       ├── SENSITIVE_FILES.md   # Sensitive files management
│       ├── PROJECT_SUMMARY.md   # Project overview
│       ├── DOCKER_BUILD_FIX.md  # Docker build troubleshooting
│       └── DOCKER_PORTS_EXPLAINED.md # Docker ports configuration
```

## Key Technical Details

### Secret Management
- Current secret: `2e96222882f7c201b73dd8bd04262571`
- Generated using: `openssl rand -hex 16`
- 32 characters (16 bytes hex) as required by MTProto
- Rotation script available: `./scripts/generate-secret.sh --update-env`

### Port Configuration
- **Main proxy**: 8443 (configurable via MTG_PORT)
- **Statistics**: 3001 (configurable via MTG_STATS_PORT)
- **Docker health**: Internal health checks

### Security Implementation
- Non-root container execution
- Read-only filesystem where possible
- Resource limits configured
- TLS camouflage support (MTG_DOMAIN)
- Anti-replay protection
- Secure logging practices

### Docker Architecture
- Multi-stage build for minimal image size
- Alpine Linux base for security
- Health checks implemented
- Proper signal handling
- Volume mounts for logs and config

## Common Operations

### Starting the Proxy
```bash
# Docker (recommended)
make docker-up
# or
docker-compose up -d

# Manual
make start
# or
./start.sh daemon
```

### Monitoring
```bash
# Real-time monitoring
make monitor
# or
./scripts/monitor.sh monitor

# Check status
make status
# or
./start.sh status
```

### Configuration Changes
```bash
# Edit configuration
nano .env

# Restart to apply changes
make restart
# or
./start.sh restart
```

### Getting Proxy Links
```bash
make links
# or
./start.sh link
```

## Potential Next Steps & Improvements

### Immediate Enhancements
1. **SSL/TLS Certificate Management**: Automated Let's Encrypt integration
2. **Multi-instance Support**: Load balancing across multiple proxies
3. **Advanced Monitoring**: Prometheus/Grafana integration
4. **Automated Deployment**: CI/CD pipeline setup
5. **Backup/Restore**: Automated configuration backup

### Advanced Features
1. **Geographic Distribution**: Multi-region deployment scripts
2. **Traffic Analysis**: Enhanced statistics and reporting
3. **Auto-scaling**: Dynamic worker adjustment
4. **Security Hardening**: Additional DDoS protection
5. **User Management**: Multi-user proxy support

### Integration Opportunities
1. **Cloud Deployment**: AWS/GCP/Azure deployment templates
2. **Kubernetes**: Helm charts and K8s manifests
3. **Monitoring Stack**: Full observability setup
4. **Security Tools**: Integration with security scanners
5. **Automation**: Ansible/Terraform modules

## Troubleshooting Common Issues

### Configuration Issues
- **Invalid secret length**: Must be exactly 32 hex characters
- **Port conflicts**: Check if ports 8443/3001 are available
- **Permission errors**: Ensure scripts are executable (`chmod +x`)

### Docker Issues
- **Build failures**: Check Docker daemon and internet connectivity
- **Container crashes**: Check logs with `docker-compose logs`
- **Port binding**: Ensure ports aren't already in use

### Network Issues
- **Connection refused**: Verify firewall settings
- **DNS resolution**: Check SERVER_HOST configuration
- **TLS errors**: Verify MTG_DOMAIN if using camouflage

## Security Considerations

### Current Security Measures
- Strong secret generation and storage
- Container security hardening
- Resource limitations
- Health monitoring
- Secure logging

### Security Checklist for Continuation
- [ ] Verify secret strength and uniqueness
- [ ] Check firewall configuration
- [ ] Validate TLS camouflage setup
- [ ] Review log retention policies
- [ ] Confirm backup procedures
- [ ] Test incident response procedures

## Development Guidelines

### Code Style
- Shell scripts follow bash best practices
- Error handling with `set -e`
- Comprehensive logging with colored output
- Modular design with clear separation of concerns

### Testing Approach
- Configuration validation
- Port accessibility testing
- Docker setup verification
- System resource checks
- End-to-end proxy functionality

### Documentation Standards
- Comprehensive README for users
- Security guide for administrators
- Inline comments in scripts
- Change logs for updates

## Integration Points

### External Dependencies
- **mtg binary**: Downloaded and compiled from 9seconds/mtg
- **Docker**: Required for containerized deployment
- **OpenSSL**: Used for secure secret generation
- **curl/wget**: Required for health checks and downloads

### Configuration Dependencies
- `.env` file must exist and be properly formatted
- Docker daemon must be running for Docker deployment
- Proper network configuration for external access
- Firewall rules for port access

## Handoff Checklist

When continuing this project, verify:
- [ ] All files are present and executable
- [ ] .env file contains valid configuration
- [ ] Docker setup is functional
- [ ] Scripts run without errors
- [ ] Documentation is current and accurate
- [ ] Security measures are properly implemented
- [ ] Testing suite passes
- [ ] Monitoring tools are functional

## Contact & Support Context

This project was built following the user's preference for best practices and comprehensive setup. The user values:
- Security-first approach
- Production-ready solutions
- Comprehensive documentation
- Automated setup processes
- Easy maintenance procedures

The implementation prioritizes reliability, security, and ease of use while providing both Docker and manual deployment options to accommodate different environments and preferences.

## Quick Reference Commands

### Essential Commands for AI Agent
```bash
# Test current state
./scripts/test-proxy.sh

# Start proxy (Docker)
make docker-up

# Start proxy (Manual)
make start

# Check status
make status

# Monitor in real-time
make monitor

# View configuration
cat .env

# Generate new secret
./scripts/generate-secret.sh --update-env

# Get proxy links
make links

# View logs
make logs

# Stop proxy
make stop  # or make docker-down
```

### File Locations for Quick Access
- **Main config**: `.env`
- **Docker setup**: `docker-compose.yml`
- **Management**: `Makefile`
- **Testing**: `scripts/test-proxy.sh`
- **Monitoring**: `scripts/monitor.sh`
- **Security guide**: `docs/SECURITY.md`
- **Sensitive files guide**: `docs/SENSITIVE_FILES.md`
- **User docs**: `README.md`
- **AI guidelines**: `.augment-guidelines`
