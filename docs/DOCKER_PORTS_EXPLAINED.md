# Docker Port Configuration Explained

## The Problem You Asked About

When using different ports in Docker, you have two main approaches:

### ❌ Wrong Approach (What was happening before)
```yaml
# docker-compose.yml
ports:
  - "9499:9499"  # Maps host port 9499 to container port 9499

# But Dockerfile only exposes:
EXPOSE 8443 3001  # Container doesn't expose port 9499!
```

This creates a mismatch where the container tries to bind to port 9499 internally, but the Dockerfile doesn't expose it.

### ✅ Correct Approach (Fixed Implementation)

**Option 1: Port Mapping (Recommended - What I implemented)**
```yaml
# docker-compose.yml
ports:
  - "9499:8443"  # Maps host port 9499 to container port 8443
  - "3001:3001"  # Maps host port 3001 to container port 3001

# Dockerfile exposes standard ports:
EXPOSE 8443 3001

# Container always uses standard ports internally
# Host exposes your custom ports externally
```

**Option 2: Dynamic Port Exposure (Alternative)**
```dockerfile
# Dockerfile with ARG
ARG MTG_PORT=8443
ARG MTG_STATS_PORT=3001
EXPOSE ${MTG_PORT} ${MTG_STATS_PORT}
```

## Why Port Mapping is Better

### 🎯 Advantages of Port Mapping (Current Implementation)

1. **Container Consistency**: Container always uses the same ports internally
2. **Image Reusability**: Same Docker image works for any external port
3. **Easier Debugging**: Standard ports inside container are predictable
4. **Better Security**: Can map to non-standard external ports while keeping internal ports standard
5. **Flexibility**: Can run multiple instances with different external ports

### 📊 How It Works Now

```
External (Your Server)     Docker Container
┌─────────────────────┐   ┌─────────────────────┐
│ Port 9499 (Proxy)  │──▶│ Port 8443 (Proxy)  │
│ Port 3001 (Stats)  │──▶│ Port 3001 (Stats)  │
└─────────────────────┘   └─────────────────────┘
```

## Current Configuration

### Production (.env.production)
```env
MTG_PORT=9499          # External port on your server
MTG_STATS_PORT=3001    # External stats port
SERVER_HOST=15.235.217.76
```

### Docker Compose (docker-compose.yml)
```yaml
ports:
  - "9499:8443"        # Host port 9499 → Container port 8443
  - "3001:3001"        # Host port 3001 → Container port 3001

environment:
  - MTG_PORT=8443      # Container uses standard port internally
  - MTG_STATS_PORT=3001
```

### Dockerfile
```dockerfile
EXPOSE 8443 3001       # Container exposes standard ports
```

## Your Proxy Links

With this configuration, your proxy links use the external ports:

**For Users:**
```
https://t.me/proxy?server=15.235.217.76&port=9499&secret=546f0de42082e730d152eebeba5f8e9a
```

**What Happens:**
1. User connects to `15.235.217.76:9499`
2. Docker maps this to container port `8443`
3. MTG proxy inside container listens on `8443`
4. Everything works seamlessly!

## Firewall Configuration

You need to open the **external** ports on your server:

```bash
# Open the external proxy port
sudo ufw allow 9499/tcp

# Stats port (optional, usually only localhost access)
sudo ufw allow 3001/tcp

# SSH access
sudo ufw allow ssh

# Enable firewall
sudo ufw enable
```

## Testing the Configuration

```bash
# Test external port accessibility
nc -zv 15.235.217.76 9499

# Test from inside container (if needed)
docker exec -it mtproto-proxy-prod nc -zv localhost 8443
```

## Benefits of This Approach

### 🔒 Security Benefits
- **Port Obscurity**: External port 9499 is non-standard, harder to detect
- **Internal Consistency**: Container always uses standard ports
- **Isolation**: Container doesn't need to know about external port configuration

### 🚀 Operational Benefits
- **Easy Scaling**: Can run multiple instances with different external ports
- **Consistent Debugging**: Always know container uses ports 8443/3001
- **Image Portability**: Same image works in any environment

### 🛠️ Development Benefits
- **Local Testing**: Can test with standard ports locally
- **CI/CD Friendly**: Same image for dev/staging/production
- **Configuration Separation**: External ports configured in compose, not image

## Alternative Approach (Not Recommended)

If you wanted dynamic port exposure in Dockerfile:

```dockerfile
# This approach is more complex and less flexible
ARG MTG_PORT=8443
ARG MTG_STATS_PORT=3001

EXPOSE ${MTG_PORT} ${MTG_STATS_PORT}

# Would require:
# docker build --build-arg MTG_PORT=9499 .
```

**Why this is worse:**
- Need to rebuild image for different ports
- More complex build process
- Less flexible deployment
- Harder to manage multiple instances

## Summary

✅ **Current Implementation (Port Mapping)**
- External: Your server uses port 9499
- Internal: Container uses port 8443
- Mapping: `9499:8443` in docker-compose.yml
- Benefits: Flexible, secure, maintainable

❌ **Previous Issue**
- Tried to use port 9499 both externally and internally
- Container wasn't configured to expose port 9499
- Would cause binding errors

The fix ensures your proxy is accessible on port 9499 externally while maintaining clean, standard configuration internally!
