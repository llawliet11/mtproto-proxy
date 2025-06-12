# MTProto Proxy Makefile
# Provides convenient commands for managing the proxy

.PHONY: help setup install start stop restart status logs clean docker-build docker-up docker-down docker-logs

# Default target
help:
	@echo "MTProto Proxy Management Commands"
	@echo ""
	@echo "Setup and Installation:"
	@echo "  setup          - Run interactive setup"
	@echo "  install        - Install proxy manually"
	@echo ""
	@echo "Proxy Management:"
	@echo "  start          - Start proxy in background"
	@echo "  stop           - Stop proxy"
	@echo "  restart        - Restart proxy"
	@echo "  status         - Show proxy status"
	@echo "  logs           - Show recent logs"
	@echo ""
	@echo "Docker Commands:"
	@echo "  docker-build   - Build Docker image"
	@echo "  docker-up      - Start with Docker Compose"
	@echo "  docker-down    - Stop Docker containers"
	@echo "  docker-logs    - Show Docker logs"
	@echo ""
	@echo "Utilities:"
	@echo "  monitor        - Start monitoring dashboard"
	@echo "  secret         - Generate new secret"
	@echo "  links          - Show proxy links"
	@echo "  clean          - Clean logs and temporary files"
	@echo ""

# Setup and installation
setup:
	@./setup.sh

install:
	@./install.sh

# Proxy management
start:
	@./start.sh daemon

stop:
	@./start.sh stop

restart:
	@./start.sh restart

status:
	@./start.sh status

logs:
	@./scripts/monitor.sh logs

# Docker commands
docker-build:
	@docker-compose build

docker-up:
	@docker-compose up -d
	@echo "Proxy started with Docker"
	@echo "Check logs with: make docker-logs"

docker-down:
	@docker-compose down

docker-logs:
	@docker-compose logs -f

# Utilities
monitor:
	@./scripts/monitor.sh monitor

secret:
	@./scripts/generate-secret.sh --update-env

links:
	@./start.sh link

clean:
	@echo "Cleaning logs and temporary files..."
	@rm -f logs/*.log
	@rm -f logs/*.pid
	@rm -f *.tmp
	@rm -f .env.tmp
	@echo "Cleanup completed"

# Development helpers
dev-setup: setup
	@echo "Development environment ready"

prod-setup: setup docker-up
	@echo "Production environment ready"

# Health check
health:
	@./scripts/monitor.sh status

# Show configuration
config:
	@echo "Current configuration:"
	@grep -v '^#' .env 2>/dev/null || echo "No .env file found"

# Backup configuration
backup:
	@mkdir -p backups
	@cp .env backups/.env.backup.$(shell date +%Y%m%d_%H%M%S) 2>/dev/null || echo "No .env file to backup"
	@echo "Configuration backed up"

# Update proxy
update:
	@echo "Updating MTProto proxy..."
	@git pull 2>/dev/null || echo "Not a git repository"
	@if [ -f docker-compose.yml ]; then \
		docker-compose pull; \
		docker-compose up -d; \
	else \
		./install.sh; \
	fi
	@echo "Update completed"
