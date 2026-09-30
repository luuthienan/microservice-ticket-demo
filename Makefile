up:
	docker compose -p microservice-ticket-demo -f docker-compose.yml up -d --build

down:
	docker compose -p microservice-ticket-demo -f docker-compose.yml down --remove-orphans
