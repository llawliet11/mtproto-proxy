# MTProto Proxy for Telegram

A secure and efficient MTProto proxy implementation for Telegram using the `mtg` (Go-based) proxy server.

## Features

- 🚀 High-performance Go implementation
- 🔒 Secure MTProto protocol support
- 🐳 Docker support for easy deployment
- 🔧 Simple configuration via environment variables
- 📊 Built-in monitoring and statistics
- 🛡️ Security best practices implemented
- 🌐 Support for multiple users
- 📱 Compatible with all Telegram clients

## Quick Start

### Prerequisites

- Docker and Docker Compose (recommended)
- OR Go 1.19+ (for manual installation)
- Linux/macOS/Windows with WSL2

### Option 1: Docker Deployment (Recommended)

1. Clone and setup:
```bash
git clone <your-repo>
cd mtproto-proxy
cp .env.example .env
```

2. Edit `.env` file with your configuration:
```bash
nano .env
```

3. Start the proxy:
```bash
docker-compose up -d
```

4. Check logs:
```bash
docker-compose logs -f
```

### Option 2: Manual Installation

1. Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

2. Configure environment:
```bash
cp .env.example .env
nano .env
```

3. Start the proxy:
```bash
./start.sh
```

## Configuration

All configuration is done via environment variables in the `.env` file:

### Required Settings

- `MTG_SECRET`: Proxy secret key (auto-generated if not set)
- `MTG_PORT`: Port to listen on (default: 8443)
- `MTG_BIND_IP`: IP address to bind to (default: 0.0.0.0)

### Optional Settings

- `MTG_DOMAIN`: Domain for TLS camouflage
- `MTG_WORKERS`: Number of worker processes
- `MTG_BUFFER_SIZE`: Buffer size for connections
- `MTG_ANTI_REPLAY_MAX_SIZE`: Anti-replay protection size
- `MTG_STATS_IP`: IP for statistics endpoint
- `MTG_STATS_PORT`: Port for statistics endpoint

### Security Settings

- `MTG_SECURE_ONLY`: Enable secure mode only
- `MTG_DISABLE_IPV6`: Disable IPv6 support
- `MTG_TIMEOUT`: Connection timeout

## Usage

### Getting Proxy Link

After starting the proxy, you'll get a connection link in the format:
```
https://t.me/proxy?server=YOUR_SERVER&port=YOUR_PORT&secret=YOUR_SECRET
```

### Adding to Telegram

1. Open the proxy link in your browser
2. Telegram will open and ask to add the proxy
3. Confirm to start using the proxy

### Monitoring

Access statistics at: `http://YOUR_SERVER:STATS_PORT/stats`

## Security Best Practices

1. **Use Strong Secrets**: Always generate strong, random secrets
2. **Firewall Configuration**: Only expose necessary ports
3. **Regular Updates**: Keep the proxy software updated
4. **Monitor Usage**: Regularly check proxy statistics
5. **Use TLS**: Enable TLS camouflage when possible
6. **Limit Access**: Consider IP whitelisting for admin access

## Troubleshooting

### Common Issues

1. **Port Already in Use**:
   ```bash
   sudo netstat -tulpn | grep :8443
   sudo kill -9 <PID>
   ```

2. **Permission Denied**:
   ```bash
   sudo chown -R $USER:$USER .
   chmod +x *.sh
   ```

3. **Connection Refused**:
   - Check firewall settings
   - Verify port configuration
   - Check if service is running

### Logs

- Docker: `docker-compose logs -f`
- Manual: Check `logs/mtg.log`

## Performance Tuning

For high-traffic scenarios:

1. Increase worker count: `MTG_WORKERS=4`
2. Adjust buffer size: `MTG_BUFFER_SIZE=65536`
3. Use dedicated server with SSD storage
4. Configure proper firewall rules
5. Monitor system resources

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This proxy is intended for legitimate use cases where Telegram access is restricted. Please comply with local laws and regulations.

## Support

For issues and questions:
- Check the troubleshooting section
- Review logs for error messages
- Open an issue on GitHub

---

**Note**: This implementation uses the `mtg` proxy server, which is a third-party implementation of the MTProto protocol. It is not officially endorsed by Telegram.
