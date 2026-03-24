.PHONY: up down tf-init tf-plan tf-apply tf-destroy dbt-run dbt-test dbt-build

# --- DOCKER (KESTRA) ---
up:
	docker-compose up -d

down:
	docker-compose down

# --- TERRAFORM (INFRAESTRUCTURA GCP) ---
tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply -auto-approve

tf-destroy:
	cd terraform && terraform destroy

# --- DBT (TRANSFORMACIÓN) ---
dbt-run:
	cd london_energy_dbt && dbt run

dbt-test:
	cd london_energy_dbt && dbt test

dbt-build:
	cd london_energy_dbt && dbt build