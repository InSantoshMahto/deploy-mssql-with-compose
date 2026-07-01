# ════════════════════════════════════════════════════════════════════════════
# SQL Server 2019 Podman Management Makefile
# Simple wrapper for shell scripts with rootless mode support
# Compose spec v3.9+ compatible
# ════════════════════════════════════════════════════════════════════════════

.PHONY: help setup start stop restart status logs connect backup restore verify \
        init-db clean clean-all ps validate stats show-compose quick-ref show-notes compose-status

# Default target
.DEFAULT_GOAL := help

# Variables
COMPOSE := podman compose
SCRIPTS_DIR := scripts
CONFIG_DIR := .config

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# ════════════════════════════════════════════════════════════════════════════
# HELP
# ════════════════════════════════════════════════════════════════════════════

help: ## Show this help message
	@echo "$(BLUE)══════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  SQL Server 2019 Podman Management$(NC)"
	@echo "$(BLUE)══════════════════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)Setup & Initialization:$(NC)"
	@echo "  make setup             - Run complete setup (setup.sh)"
	@echo "  make init-db           - Initialize database (scripts/init-db.sh)"
	@echo ""
	@echo "$(GREEN)Container Management:$(NC)"
	@echo "  make start             - Start SQL Server (podman compose up -d)"
	@echo "  make stop              - Stop SQL Server (podman compose down)"
	@echo "  make restart           - Restart SQL Server (podman compose restart)"
	@echo "  make status            - Show container status (podman compose ps)"
	@echo "  make logs              - View logs (podman compose logs -f)"
	@echo ""

	@echo "$(GREEN)Database Operations:$(NC)"
	@echo "  make connect           - Connect to SQL Server (scripts/connect.sh)"
	@echo "  make backup DB=AppDB                      - Backup database (scripts/backup.sh)"
	@echo "  make restore FILE=backup.bak TARGET=AppDB - Restore database (scripts/restore.sh)"
	@echo "  make verify            - Run verification checks (scripts/verify.sh)"
	@echo ""
	@echo "$(GREEN)Cleanup:$(NC)"
	@echo "  make clean             - Stop and remove containers (keeps volumes)"
	@echo "  make clean-all         - Stop, remove containers and volumes"
	@echo ""

# ════════════════════════════════════════════════════════════════════════════
# SETUP & INITIALIZATION
# ════════════════════════════════════════════════════════════════════════════

setup: ## Run complete setup (configures user for rootless mode)
	@bash setup.sh

init-db: ## Initialize database
	@bash $(SCRIPTS_DIR)/init-db.sh

# ════════════════════════════════════════════════════════════════════════════
# CONTAINER MANAGEMENT
# ════════════════════════════════════════════════════════════════════════════

start: ## Start SQL Server (podman compose up -d)
	@$(COMPOSE) up -d

stop: ## Stop SQL Server (podman compose down)
	@$(COMPOSE) down

restart: ## Restart SQL Server (podman compose restart)
	@$(COMPOSE) restart

status: ## Show container status (podman compose ps)
	@$(COMPOSE) ps

ps: status ## Alias for status

logs: ## View logs (follow mode)
	@$(COMPOSE) logs -f

# ──────────────────────────────────────── ROOTLESS MODE CONFIGURATION ────────────────────────────────────────
# Configure rootless mode user (UID:GID) for non-root operation
# Uses $(shell id -u):$(shell id -g) to detect current user's UID and GID

# ════════════════════════════════════════════════════════════════════════════
# DATABASE OPERATIONS
# ════════════════════════════════════════════════════════════════════════════

connect: ## Connect to SQL Server (scripts/connect.sh)
	@bash $(SCRIPTS_DIR)/connect.sh

backup: ## Backup database (usage: make backup DB=AppDB)
	@bash $(SCRIPTS_DIR)/backup.sh $(DB)

restore: ## Restore database (usage: make restore FILE=backup.bak TARGET=AppDB)
	@bash $(SCRIPTS_DIR)/restore.sh $(FILE) $(TARGET)

verify: ## Run verification checks (scripts/verify.sh)
	@bash $(SCRIPTS_DIR)/verify.sh

# ──────────────────────────────────────── RESOURCE MANAGEMENT ────────────────────────────────────────
# Podman-specific resource hints beyond compose.yaml deploy.resources

# ════════════════════════════════════════════════════════════════════════════
# CLEANUP
# ════════════════════════════════════════════════════════════════════════════

clean: ## Stop and remove containers (keeps volumes)
	@$(COMPOSE) down

clean-all: ## Stop, remove containers and volumes
	@echo "$(YELLOW)WARNING: This will delete all database data!$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to cancel, or wait 5 seconds...$(NC)"
	@sleep 5
	@$(COMPOSE) down -v



# ════════════════════════════════════════════════════════════════════════════
# PODMAN-SPECIFIC UTILITIES
# ════════════════════════════════════════════════════════════════════════════

# Validate compose.yaml and show basic info
validate: ## Validate compose.yaml configuration
	@echo "$(BLUE)Validating Podman Compose Configuration...$(NC)"
	@if $(COMPOSE) config; then \
	  echo ""; \
	  echo "$(GREEN)✓ Compose file validated successfully$(NC)"; \
	else \
	  echo "$(RED)✗ Compose file validation failed!$(NC)"; \
	fi

# Show Podman stats for running containers (resource usage monitoring)
stats: ## Show current resource usage statistics for SQL Server container
	@echo "$(BLUE)SQL Server Resource Statistics$(NC)"
	@podman stats --no-stream mssql-server-2019 2>/dev/null || echo "$(YELLOW)! Container not running$(NC)"

# Display compose file with Podman-specific configuration
show-compose: ## Show current compose.yaml configuration
	@echo "$(BLUE)Current SQL Server Configuration$(NC)"
	@echo ""
	@grep -A 50 "services:" $(CURDIR)/compose.yaml | grep -v "^-" | head -30

# ════════════════════════════════════════════════════════════════════════════
# NOTES & DOCUMENTATION
# ════════════════════════════════════════════════════════════════════════════

# Show quick reference for Podman-specific commands
quick-ref: ## Quick reference for Podman-specific SQL Server management
	@echo "$(BLUE)Quick Reference - SQL Server 2019 on Podman$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Basic Commands:$(NC)"
	@echo "   $(GREEN)make start$(NC)          - Start SQL Server"
	@echo "   $(GREEN)make stop$(NC)           - Stop SQL Server"
	@echo "   $(GREEN)make status$(NC)         - Show container status"
	@echo "   $(GREEN)make logs$(NC)           - View logs in real-time"
	@echo ""
	@echo "$(YELLOW)2. Podman-specific Commands:$(NC)"
	@echo "   $(GREEN)podman machine start$(NC)        - Start Podman Machine (macOS/WSL2)"
	@echo "   $(GREEN)podman generate systemd$(NC)     - Generate systemd service"
	@echo "   $(GREEN)podman stats$(NC)                - Show resource usage"
	@echo "   $(GREEN)podman logs -f$(NC)              - Follow log output"
	@echo "   $(GREEN)journalctl -u mssql-server-2019$(NC) - View systemd journal logs"
	@echo ""
	@echo "$(YELLOW)3. Rootless Mode Configuration (if using non-root user):$(NC)"
	@echo "   User is set to: \$(shell id -u):$(shell id -g) automatically"
	@echo "   If issues occur, run as rootful: $(RED)sudo podman compose up -d$(NC)"
	@echo ""
	@echo "$(YELLOW)4. Logging Configuration (k8s-file driver):$(NC)"
	@echo "   Logs go to Podman journal; check with:"
	@echo "     $(GREEN)podman logs mssql-server-2019$(NC)"
	@echo "     $(GREEN)journalctl -u mssql-server-2019 -f -n 50$(NC)"
	@echo ""

# ════════════════════════════════════════════════════════════════════════════
# NOTES AND IMPORTANT CONSIDERATIONS
# ════════════════════════════════════════════════════════════════════════════

show-notes: ## Display important Podman-specific notes and considerations
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  SQL Server 2019 Podman Management - Important Notes             ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "1. ROOTLESS MODE SUPPORT"
	@echo "   - User automatically set to your UID:GID for non-root operation"
	@echo "   - If you encounter permission errors, run as rootful:"
	@echo "     $(RED)sudo podman compose up -d$(NC)"
	@echo ""
	@echo "2. LOGGING CONFIGURATION (k8s-file driver)"
	@echo "   - Uses Podman's k8s-file logging driver for systemd integration"
	@echo "   - Max log file size: 10MB, backups to 3 files, compression enabled"
	@echo "   - Check logs with:"
	@echo "     • $(GREEN)podman logs -f mssql-server-2019$(NC) (standard)"
	@echo "     • $(GREEN)journalctl -u mssql-server-2019 -f -n 50$(NC) (systemd journal)"
	@echo ""
	@echo "3. RESOURCE MANAGEMENT"
	@echo "   - compose.yaml deploy.resources for CPU/memory limits"
	@echo "   - Podman-specific: mem_limit, memswap_limit, cpu_shares available"
	@echo "   - Current settings:"
	@echo "     • Limits: 1.5 CPU cores, 6GB memory"
	@echo "     • Reservations: 1.0 CPU cores, 4GB memory"
	@echo ""

	@echo "5. START_INTERVAL REMOVED (Compose spec v3.9+ limitation)"
	@echo "   - start_interval: 5s removed from healthcheck"
	@echo "   - SQL Server still works normally with standard health checks"
	@echo "   - Default interval: 30s as specified in healthcheck.test"
	@echo ""
	@echo "6. COMPOSE FILE CONFIGURATION"
	@echo "   - Uses Podman Compose v5.x compatible format"
	@echo "   - Volumes: mssql-data, mssql-log, backups"
	@echo ""

# Show compose file status (quick validation)
compose-status: ## Quick validate and show basic compose configuration
	@if $(COMPOSE) config 2>/dev/null; then \
	  echo ""; \
	  echo "$(GREEN)✓ Compose file is valid and Podman-compose compatible$(NC)"; \
	else \
	  echo "$(RED)✗ Compose file validation failed!$(NC)"; \
	  exit 1; \
	fi

# ════════════════════════════════════════════════════════════════════════════
# END OF MAKEFILE
# ════════════════════════════════════════════════════════════════════════════
