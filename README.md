# ⚡ Smart Meters in London: End-to-End Data Engineering Pipeline

![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-Passing-success?style=for-the-badge&logo=githubactions)
![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?style=for-the-badge&logo=terraform)
![Kestra](https://img.shields.io/badge/Kestra-Orchestration-2C007A?style=for-the-badge)
![dbt](https://img.shields.io/badge/dbt-Transformations-FF694B?style=for-the-badge&logo=dbt)
![GCP](https://img.shields.io/badge/GCP-BigQuery-4285F4?style=for-the-badge&logo=googlecloud)

## 1. ⚡ Project Overview

### 🎯 The Problem
The transition to smart energy grids generates massive amounts of high-frequency data. For this project, I tackled the **Smart Meters in London** dataset, which contains half-hourly energy consumption readings for over 5,500 households, amounting to nearly 170 million individual records.

The main challenge was not just handling this volume of data, but enriching it to extract actionable insights. The goal was to analyze how energy consumption behavior is driven by two external dimensions:
* **Weather Conditions:** Crossing historical consumption data with daily temperature metrics to detect seasonal patterns.
* **Socio-Economic Profiles:** Segmenting households using the ACORN classification to understand how different demographic groups consume energy throughout the day (detecting peak hours and baseline usage).

### 🚀 The Goal
The primary objective of this capstone project is to build a robust, scalable, and fully automated **ELT (Extract, Load, Transform)** data pipeline applying the best practices of modern data engineering. 

Key achievements of this architecture include:
* **Infrastructure as Code (IaC):** Managing Google Cloud resources (GCS, BigQuery) entirely via Terraform.
* **Modern Data Stack:** Utilizing **Kestra** for workflow orchestration, **dlt** for reliable data ingestion, and **dbt** for data modeling and testing.
* **Data Warehouse Optimization:** Implementing partitioning and clustering in BigQuery to ensure cost-effective and highly performant queries for the dashboard.
* **CI/CD Integration:** Automating code formatting checks and SQL syntax validation using GitHub Actions.

---

## 2. 🏗️ Architecture & Tech Stack

### 🗺️ Pipeline Architecture
*(Note: Replace this placeholder with a screenshot/image of your architecture diagram)*
`![Architecture Diagram](link_to_your_diagram_image.png)`

The pipeline follows a modern ELT (Extract, Load, Transform) approach, orchestrated end-to-end:

1. **Extraction & Loading (Hybrid Approach):** Data is extracted from Kaggle via API orchestrated by Kestra. To optimize performance, a hybrid loading strategy was implemented:
   * **Dimensional Data:** Small metadata tables (weather and household profiles) are ingested and loaded directly into BigQuery using **dlt**.
   * **Fact Data (Massive Volume):** The heavy `hhblock` dataset is uploaded directly to Google Cloud Storage (GCS) and mounted in BigQuery as an **External Table**. This bypasses unnecessary processing bottlenecks during ingestion.
2. **Transformation:** Once in the Data Warehouse, **dbt** takes over to clean, unpivot, test, and model the data into production-ready data marts.
3. **Visualization:** Looker Studio connects directly to the optimized BigQuery marts to serve the final dashboards.

### 🛠️ Technologies Used
* **Cloud Platform:** Google Cloud Platform (GCP)
  * **Data Lake:** Google Cloud Storage (GCS)
  * **Data Warehouse:** BigQuery
* **Infrastructure as Code (IaC):** Terraform
* **Workflow Orchestration:** Kestra
* **Data Ingestion:** dlt (data load tool)
* **Data Transformation & Testing:** dbt (Data Build Tool) core
* **Business Intelligence:** Looker Studio

---

## 3. 📊 The Dataset

The core data for this project comes from the **Smart Meters in London** dataset available on Kaggle. It tracks the energy consumption of 5,567 households in London that took part in the UK Power Networks led Low Carbon London project between November 2011 and February 2014.

The project utilizes three main tables:
1. **Consumption Data (`hhblock_dataset`):** Half-hourly energy readings.
2. **Household Profiles (`informations_households`):** Socio-economic classification (ACORN groups) for each meter.
3. **Weather Data (`weather_daily_darksky`):** Daily maximum and minimum temperatures in Celsius.

### 🧠 Strategic Design Decision: Optimizing Ingestion
The Kaggle dataset offers the consumption data in two formats: a "long" format (~167 million rows) and a "wide" block format (`hhblock`, ~3.5 million rows where each row contains 48 half-hour columns for a single day).

**Architectural Choice:** Instead of ingesting the massive 167M row file, I intentionally chose to extract and load the `hhblock` dataset. 
* **Why?** This significantly optimized network bandwidth and ingestion time from the source to the Data Lake. 
* **The Trade-off:** The data arrived in BigQuery in an unnormalized state. I pushed the heavy computational lifting (unpivoting 48 columns into rows) to the Data Warehouse layer using **dbt**, leveraging BigQuery's massive parallel processing capabilities to handle the transformation in seconds rather than bottlenecking the ingestion pipeline.

---

## 4. ⚙️ Data Modeling & Transformations (dbt)

With the raw data residing in BigQuery, **dbt (Data Build Tool)** is used to transform, clean, and model the data into production-ready marts. The dbt project is structured into two main layers:

### 🛠️ Staging Layer (Views)
* Materialized as `views` to provide a clean, standardized interface over the raw sources.
* Renames columns, casts data types, and handles the initial parsing of dates and temperatures.

### 🏭 Production / Marts Layer (Tables)
This is where the heavy computational lifting happens. The models are materialized as `tables` and heavily optimized:
* **The `UNPIVOT` Magic:** The raw `hhblock` external table contains 48 columns (one for each half-hour of the day). A complex SQL transformation is applied to unpivot these columns into a normalized, long-format time-series structure.
* **Data Quality Tests:** Strict data testing is enforced using `schema.yml`. This includes `not_null` constraints, referential integrity, and rigorous `accepted_values` checks (e.g., ensuring hours of the day are strictly between 0 and 23) using data type enforcement.
* **Optimization (Partitioning & Clustering):** To ensure Looker Studio queries remain performant and cost-effective, the final daily mart (`mart_daily_energy_weather`) is:
  * **Partitioned by:** `consumption_date` (Daily granularity).
  * **Clustered by:** `acorn_group` and `household_id`.

---

## 5. 📈 Dashboard & Insights (Visualizing London's Consumption)

The final presentation layer is a high-performance, interactive dashboard built on **Looker Studio**. It connects directly to the optimized and partitioned BigQuery data marts (`mart_daily_energy_weather` and `mart_hourly_profile`). The dashboard is designed around a professional dark theme to provide a clear and engaging analytical experience.

*(Note: The four gauge scorecards at the top are currently under development. The main analytical tiles below are fully functional).*

<p align="center">
  <img src="https://raw.githubusercontent.com/user_name/repo_name/main/image_0.png" alt="Smart Meters London Dashboard" width="90%">
</p>

### 💡 Key Analytical Tiles & Business Insights

The dashboard is structured into four main analytical sections to answer core energy questions:

#### A. 🦆 Hourly Consumption Patterns (The "Duck Curve")
* **Visualization:** Interactive Line Chart with breakdown by socio-economic groups.
* **Insight:** This chart shows the normalized average consumption profile for the 24 hours of a day. It reveals distinct "peaks" and "valleys".
    * **The Evening Peak:** A sharp increase in demand around 18:00 (6 PM) across all demographics, representing when people return home.
    * **Demographic Segmentation:** We can clearly see the different baselines for **Affluent** (highest consumption curve, in blue) vs. **Comfortable** (middle, in yellow) vs. **Adversity** (lowest baseline, in purple) groups. This segmentation is crucial for utility companies designing targeted energy-saving programs.

#### B. 📊 Average Consumption Breakdown (Demographics)
* **Visualization:** Donut Chart showing percentage distribution.
* **Insight:** This provides a clear breakdown of which demographic group is responsible for what percentage of total energy use. It complements the temporal view by providing a non-time-series, categorical distribution of the market share. (e.g., Affluent representing 11.52% vs. Adversity at 8.54% of average consumption per household).

#### C. 🏖️ Holiday vs. Weekday Consumption (Business Days Impact)
* **Visualization:** Stacked Bar Chart comparing Business Days (Weekday) vs. Holidays & Weekends.
* **Insight:** An important operational view for predicting demand. It analyzes how different household types alter their consumption behavior on non-working days. Understanding if the evening peak shifts or if overall usage increases on holidays is critical for grid stabilization.

#### D. ☀️ Weather Impact Analysis (Correlation View)
* **Visualization:** Complex Time-Series area and line chart over a multi-year period (Nov 2011 - Feb 2014) and a detailed top 15 list.
* **Insight:** This chart visually proves the inverse correlation between daily maximum temperatures (`max_temp_celsius` in red) and total energy demand across London (`total_kwh` as a white area).
    * **Seasonal Fluctuations:** Consumption peaks in the cold winter months (Dec-Jan) and plummets during the warm summer months (Jun-Aug). The detailed table to the right lists the months with the highest usage, directly related to extreme temperatures. This is a crucial model for energy traders to forecast seasonal prices.

---

## 6. 🤖 CI/CD Pipeline (Continuous Integration)

To ensure code quality and prevent broken code from reaching the main branch, a Continuous Integration (CI) pipeline was implemented using **GitHub Actions**.

Whenever a `push` or `pull_request` is made to the `main` branch, a virtual environment is spun up to automatically run two critical jobs:
1. **Terraform Inspector:** Executes `terraform fmt -check` and `terraform validate` to ensure the Infrastructure as Code is properly formatted and syntactically correct.
2. **dbt Compiler:** Creates a dummy `profiles.yml` and runs `dbt parse` to catch any SQL syntax errors or missing dependencies in the transformation layer before deployment.

*(Note: Continuous Deployment (CD) of the data itself is handled securely by **Kestra**, keeping Google Cloud credentials completely isolated from the public GitHub repository).*

---

## 7. 🛠️ Reproducibility (How to run this project)

This project was built with reproducibility in mind. By using a `Makefile`, the entire infrastructure and orchestration layer can be spun up with just a few commands.

### 📋 Prerequisites
Before you begin, ensure you have the following installed and configured:
* **Google Cloud Platform (GCP):** A project with a Service Account that has `Owner` or `Editor` privileges. Download the JSON key.
* **Kaggle API:** An account on Kaggle to download the `kaggle.json` API key.
* **Tools:** `Docker`, `Docker Compose`, `Terraform`, and `Make` installed on your local machine.

### 🏗️ Step-by-Step Setup

**Step 1: Clone the repository**
```bash
git clone [https://github.com/axl-builder/london-smartmeter-energy-pipeline.git](https://github.com/axl-builder/london-smartmeter-energy-pipeline.git)
cd london-smartmeter-energy-pipeline

Gemini ha dicho
¡Excelente, Axel! Vamos a ponerle el techo a esta casa y entregar las llaves.

Estas últimas tres secciones son las que le dicen al evaluador del Zoomcamp y a los reclutadores: "No solo sé programar, sino que sé empaquetar mi trabajo para que otros lo usen sin dolores de cabeza". El uso del Makefile acá es tu carta de triunfo.

Copiá y pegá este último bloque para cerrar tu README.md:

Markdown
## 6. 🤖 CI/CD Pipeline (Continuous Integration)

To ensure code quality and prevent broken code from reaching the main branch, a Continuous Integration (CI) pipeline was implemented using **GitHub Actions**.

Whenever a `push` or `pull_request` is made to the `main` branch, a virtual environment is spun up to automatically run two critical jobs:
1. **Terraform Inspector:** Executes `terraform fmt -check` and `terraform validate` to ensure the Infrastructure as Code is properly formatted and syntactically correct.
2. **dbt Compiler:** Creates a dummy `profiles.yml` and runs `dbt parse` to catch any SQL syntax errors or missing dependencies in the transformation layer before deployment.

*(Note: Continuous Deployment (CD) of the data itself is handled securely by **Kestra**, keeping Google Cloud credentials completely isolated from the public GitHub repository).*

---

## 7. 🛠️ Reproducibility (How to run this project)

This project was built with reproducibility in mind. By using a `Makefile`, the entire infrastructure and orchestration layer can be spun up with just a few commands.

### 📋 Prerequisites
Before you begin, ensure you have the following installed and configured:
* **Google Cloud Platform (GCP):** A project with a Service Account that has `Owner` or `Editor` privileges. Download the JSON key.
* **Kaggle API:** An account on Kaggle to download the `kaggle.json` API key.
* **Tools:** `Docker`, `Docker Compose`, `Terraform`, and `Make` installed on your local machine.

### 🏗️ Step-by-Step Setup

**Step 1: Clone the repository**
```bash
git clone [https://github.com/axl-builder/london-smartmeter-energy-pipeline.git](https://github.com/axl-builder/london-smartmeter-energy-pipeline.git)
cd london-smartmeter-energy-pipeline
```

**Step 2: Configure Credentials & Variables**

Place your GCP Service Account key inside the terraform/ folder (or update the path in variables.tf).

Place your kaggle.json key where Kestra can access it (as defined in your Kestra flow).

Update the project_id and bucket_name variables in the terraform/variables.tf file to match your unique GCP project.

**Step 3: Provision the Cloud Infrastructure**
Use the Makefile to initialize and deploy the GCS Bucket and BigQuery Datasets via Terraform.

```bash
make tf-init
make tf-apply
```

(Type yes when prompted by Terraform).

**Step 4: Start the Orchestrator**
Spin up Kestra and its dependencies locally using Docker Compose.

```bash
make up
```

Once running, navigate to http://localhost:8080 in your browser.

**Step 5: Execute the ELT Pipeline**

In the Kestra UI, import the .yaml flow files from the kestra/ directory.

Click Execute on the main pipeline flow.

Grab a coffee! Kestra will automatically download the data via dlt, upload it to GCS, mount it to BigQuery, and trigger the dbt transformations.

**Step 6: Tear Down (Demolition)**
To avoid incurring unwanted cloud costs once you are done evaluating the project, destroy the infrastructure and spin down the local Docker containers:

```bash
make tf-destroy
make down
```

---

8. 🎓 Acknowledgements
This project was developed as the Capstone Project for the Data Engineering Zoomcamp (2026) by DataTalks.Club. A huge thank you to the instructors and the amazing community for the incredible learning journey!

