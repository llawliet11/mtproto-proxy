# Security Guide for MTProto Proxy

This document outlines security best practices for deploying and maintaining your MTProto proxy server.

## 🔒 Security Best Practices

### 1. Server Security

#### Operating System Hardening
- **Keep system updated**: Regularly update your OS and packages
- **Disable root login**: Use sudo instead of direct root access
- **Configure firewall**: Only open necessary ports
- **Use SSH keys**: Disable password authentication for SSH

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Configure UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 8443/tcp  # Your proxy port
sudo ufw enable
```

#### User Management
- **Create dedicated user**: Don't run proxy as root
- **Limit privileges**: Use principle of least privilege
- **Monitor access**: Check login logs regularly

```bash
# Create dedicated user
sudo adduser mtproxy
sudo usermod -aG docker mtproxy  # If using Docker
```

### 2. Proxy Configuration Security

#### Secret Management
- **Strong secrets**: Use cryptographically secure random secrets
- **Regular rotation**: Change secrets periodically
- **Secure storage**: Never commit secrets to version control

```bash
# Generate strong secret
openssl rand -hex 16

# Rotate secret
./scripts/generate-secret.sh --update-env
```

#### Network Security
- **Use non-standard ports**: Avoid common ports like 80, 443
- **Enable TLS camouflage**: Use domain fronting when possible
- **Limit connections**: Set reasonable connection limits

```env
# Example secure configuration
MTG_PORT=8443
MTG_DOMAIN=www.google.com
MTG_SECURE_ONLY=true
MTG_MAX_CONNECTIONS_PER_IP=10
```

### 3. Monitoring and Logging

#### Log Management
- **Enable logging**: Monitor all proxy activity
- **Log rotation**: Prevent logs from filling disk
- **Secure logs**: Protect log files from unauthorized access

```bash
# Set up log rotation
sudo tee /etc/logrotate.d/mtproxy << EOF
/path/to/mtproxy/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 mtproxy mtproxy
}
EOF
```

#### Monitoring Setup
- **Resource monitoring**: Track CPU, memory, disk usage
- **Connection monitoring**: Monitor active connections
- **Alert setup**: Set up alerts for unusual activity

```bash
# Monitor proxy
./scripts/monitor.sh monitor

# Check statistics
curl http://localhost:3001/stats
```

### 4. Docker Security

#### Container Security
- **Non-root user**: Run containers as non-root
- **Read-only filesystem**: Use read-only containers when possible
- **Resource limits**: Set memory and CPU limits
- **Security options**: Enable security features

```yaml
# docker-compose.yml security settings
services:
  mtproto-proxy:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'
```

#### Image Security
- **Official images**: Use official or trusted base images
- **Regular updates**: Keep base images updated
- **Vulnerability scanning**: Scan images for vulnerabilities

```bash
# Update Docker images
docker-compose pull
docker-compose up -d
```

### 5. Network Security

#### Firewall Configuration
```bash
# iptables rules for proxy
sudo iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3001 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -j DROP

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

#### DDoS Protection
- **Rate limiting**: Implement connection rate limits
- **IP blocking**: Block suspicious IPs
- **Load balancing**: Use multiple proxy instances

```bash
# Rate limiting with iptables
sudo iptables -A INPUT -p tcp --dport 8443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
```

### 6. Privacy Protection

#### Data Minimization
- **No logging of user data**: Don't log user messages or metadata
- **Minimal statistics**: Only collect necessary metrics
- **Regular cleanup**: Clean old logs and temporary files

#### Anonymity
- **VPN/Tor**: Consider running proxy through VPN or Tor
- **Multiple locations**: Use different server locations
- **Domain fronting**: Use TLS camouflage with popular domains

### 7. Incident Response

#### Preparation
- **Backup configuration**: Regular backups of configuration
- **Recovery plan**: Document recovery procedures
- **Contact information**: Keep emergency contacts updated

```bash
# Backup configuration
make backup

# Quick recovery
cp backups/.env.backup.latest .env
make restart
```

#### Detection
- **Log monitoring**: Monitor for suspicious activity
- **Performance monitoring**: Watch for unusual resource usage
- **Connection monitoring**: Track connection patterns

#### Response
- **Immediate actions**: Stop proxy if compromised
- **Investigation**: Analyze logs and system state
- **Recovery**: Restore from clean backup

```bash
# Emergency stop
make stop
# or
docker-compose down

# Investigate
./scripts/monitor.sh logs 100
```

### 8. Compliance and Legal

#### Legal Considerations
- **Local laws**: Understand local regulations
- **Terms of service**: Comply with hosting provider ToS
- **User notification**: Inform users about proxy usage

#### Data Protection
- **No data retention**: Don't store user communications
- **Secure deletion**: Properly delete any temporary data
- **Access controls**: Limit who can access the proxy

### 9. Security Checklist

Before deploying your proxy, ensure:

- [ ] Server is hardened and updated
- [ ] Firewall is properly configured
- [ ] Strong, unique secret is generated
- [ ] Non-root user is used
- [ ] Logging is enabled and secured
- [ ] Monitoring is set up
- [ ] Backup procedures are in place
- [ ] Legal compliance is verified

### 10. Regular Maintenance

#### Weekly Tasks
- [ ] Check system updates
- [ ] Review logs for anomalies
- [ ] Monitor resource usage
- [ ] Verify proxy functionality

#### Monthly Tasks
- [ ] Rotate proxy secret
- [ ] Update Docker images
- [ ] Review security configurations
- [ ] Test backup/recovery procedures

#### Quarterly Tasks
- [ ] Security audit
- [ ] Performance optimization
- [ ] Documentation updates
- [ ] Compliance review

## 🚨 Security Incidents

If you suspect a security incident:

1. **Immediately stop the proxy**
2. **Preserve logs and evidence**
3. **Assess the scope of compromise**
4. **Notify relevant parties**
5. **Implement containment measures**
6. **Recover from clean backups**
7. **Conduct post-incident review**

## 📞 Getting Help

For security-related questions or incidents:
- Review this security guide
- Check the troubleshooting section in README.md
- Open an issue on GitHub (for non-sensitive matters)
- Contact security experts for serious incidents

Remember: Security is an ongoing process, not a one-time setup. Stay vigilant and keep your proxy updated and monitored.
