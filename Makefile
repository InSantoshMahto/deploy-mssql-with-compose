# ══════════════════════════════════════════════════════════════════════════════
# SQL Server 2019 Docker Management Makefile
# Simple wrapper for shell scripts
# ══════════════════════════════════════════════════════════════════════════════

.PHONY: help setup start stop restart status logs connect backup restore verify \
        init-db clean ps health

# Default target
.DEFAULT_GOAL := help

# Variables
COMPOSE := docker compose
SCRIPTS_DIR := scripts

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# ══════════════════════════════════════════════════════════════════════════════
# HELP
# ══════════════════════════════════════════════════════════════════════════════

help: ## Show this help message
	@echo "$(BLUE)══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  SQL Server 2019 Docker Management$(NC)"
	@echo "$(BLUE)══════════════════════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)Setup & Initialization:$(NC)"
	@echo "  make setup          - Run complete setup (setup.sh)"
	@echo "  make init-db        - Initialize database (scripts/init-db.sh)"
	@echo ""
	@echo "$(GREEN)Container Management:$(NC)"
	@echo "  make start          - Start SQL Server (docker compose up -d)"
	@echo "  make stop           - Stop SQL Server (docker compose down)"
	@echo "  make restart        - Restart SQL Server (docker compose restart)"
	@echo "  make status         - Show container status (docker compose ps)"
	@echo "  make logs           - View logs (docker compose logs -f)"
	@echo ""
	@echo "$(GREEN)Database Operations:$(NC)"
	@echo "  make connect        - Connect to SQL Server (scripts/connect.sh)"
	@echo "  make backup AppDB   - Backup database (scripts/backup.sh)"
	@echo "  make restore backup.bak TargetDB - Restore database (scripts/restore.sh)"
	@echo "  make verify         - Run verification (scripts/verify.sh)"
	@echo ""
	@echo "$(GREEN)Cleanup:$(NC)"
	@echo "  make clean          - Stop and remove containers"
	@echo "  make clean-all      - Stop, remove containers and volumes"
	@echo ""

# ══════════════════════════════════════════════════════════════════════════════
# SETUP & INITIALIZATION
# ══════════════════════════════════════════════════════════════════════════════

setup: ## Run complete setup
	@bash setup.sh

init-db: ## Initialize database
	@bash $(SCRIPTS_DIR)/init-db.sh

# ══════════════════════════════════════════════════════════════════════════════
# CONTAINER MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

start: ## Start SQL Server
	@$(COMPOSE) up -d

stop: ## Stop SQL Server
	@$(COMPOSE) down

restart: ## Restart SQL Server
	@$(COMPOSE) restart

status: ## Show container status
	@$(COMPOSE) ps

ps: status ## Alias for status

logs: ## View logs (follow mode)
	@$(COMPOSE) logs -f

health: ## Check container health
	@docker inspect --format='{{.State.Health.Status}}' mssql-server-2019 2>/dev/null || echo "Container not running"

# ══════════════════════════════════════════════════════════════════════════════
# DATABASE OPERATIONS
# ══════════════════════════════════════════════════════════════════════════════

connect: ## Connect to SQL Server
	@bash $(SCRIPTS_DIR)/connect.sh

backup: ## Backup database (usage: make backup DatabaseName)
	@bash $(SCRIPTS_DIR)/backup.sh $(filter-out $@,$(MAKECMDGOALS))

restore: ## Restore database (usage: make restore backup_file.bak TargetDB)
	@bash $(SCRIPTS_DIR)/restore.sh $(filter-out $@,$(MAKECMDGOALS))

verify: ## Run verification checks
	@bash $(SCRIPTS_DIR)/verify.sh

# Catch-all target to allow positional arguments
%:
	@:

# ══════════════════════════════════════════════════════════════════════════════
# CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

clean: ## Stop and remove containers (keeps volumes)
	@$(COMPOSE) down

clean-all: ## Stop and remove containers and volumes
	@echo "$(YELLOW)WARNING: This will delete all database data!$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to cancel, or wait 5 seconds...$(NC)"
	@sleep 5
	@$(COMPOSE) down -v
