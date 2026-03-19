# london-smartmeter-energy-pipeline

#
london-smart-energy-pipeline/
├── terraform/          # Etapa 1: Tu "Obrador" (Infraestructura)
├── kestra/             # Etapa 2 y 3: Los "Planos de Orquestación" (Flows)
├── dlt_ingestion/      # Los scripts de Python gestionados con uv
├── dbt_transform/      # Etapa 4: La "Refinería" de datos
├── README.md           # Tu Memoria Descriptiva (Vital)
├── pyproject.toml      # El inventario de materiales (uv)
└── .gitignore          # Lo que NO entra en la obra (llaves JSON, .venv)
