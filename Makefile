COMPOSE = docker compose -p microservice-ticket-demo -f docker-compose.yml

.PHONY: up down shell-auth shell-orders shell-tickets shell-payments

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down --remove-orphans

shell-auth:
	$(COMPOSE) exec auth bash

shell-orders:
	$(COMPOSE) exec orders bash

shell-tickets:
	$(COMPOSE) exec tickets bash

shell-payments:
	$(COMPOSE) exec payments bash
