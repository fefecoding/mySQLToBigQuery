# MySQL to BigQuery Data Pipeline

This project is my hands-on practice building a data pipeline from MySQL to BigQuery. I wanted to understand the full flow — from setting up a database, generating realistic test data, transforming it with SQL, and getting it into BigQuery for analytics.

---

## What I Built

The pipeline does a few things:

1. **Runs MySQL in Docker** — so it's easy to spin up and tear down
2. **Generates mock data** — students, schools, courses, and enrollments using stored procedures and UDFs
3. **Transforms the data** — joins tables into a clean, analytics-ready format
4. **Pushes to BigQuery** — replicates the final dataset to Google Cloud for querying

---

## Tech Stack

- **Docker** — containerized MySQL + Adminer (for a UI)
- **MySQL** — relational database with foreign keys and constraints
- **Google Cloud Platform** — Compute Engine, Container Registry, BigQuery
- **SQL** — stored procedures, user-defined functions, data modeling

---

## Step-by-Step Walkthrough

### Quick Setup (One Command)

I added a setup script that does everything automatically:

```bash
chmod +x setup.sh
./setup.sh
```

This will build the containers, wait for MySQL to be ready, and run all the SQL scripts in the right order.

---

### Manual Setup (Step by Step)

If you prefer to do it manually, here's how:

**1. Start the containers:**
```bash
docker-compose up -d
```

This starts two containers:
- **MySQL** — the database (port 3306)
- **Adminer** — a lightweight web UI for browsing the DB (port 8080)

Check it's running with `docker ps`, then head to `http://localhost:8080` and log in with the credentials from the `.env` file.

**2. Load UDFs** — custom functions for generating random data:
```bash
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/udf.sql
```

**3. Create stored procedures** — automates bulk data insertion:
```bash
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/store_procedure.sql
```

**4. Generate mock data** — populates tables:
```bash
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/populate_data.sql
```
This creates 1,000 students, 10 schools, 3 courses, and 3,000 enrollment records.

**5. Add foreign keys** — enforces referential integrity:
```bash
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/modeling_data.sql
```

---

### Step 3: Transform Data for BigQuery

The raw tables are normalized (good for OLTP), but for analytics we want a flatter, denormalized structure. The `scripts/to_bigquery.sql` script joins everything into a single `bq_data` table:

```sql
CREATE TABLE bq_data AS
SELECT id_std, name_std, dob_std, name_sch, name_crs, date_regist
FROM students JOIN schools ... JOIN courses ...
```

You can preview it:
```sql
SELECT * FROM bq_data LIMIT 20;
```

---

### Step 4: Deploy MySQL to GCP

To make the database accessible from BigQuery (or just to host it in the cloud), I pushed the Docker image to GCP:

**Tag and push to Docker Hub:**
```bash
docker tag <local_image> trannammai/final_mysql_image
docker push trannammai/final_mysql_image
```

**Move to GCP Container Registry:**
```bash
docker pull trannammai/final_mysql_image
docker tag trannammai/final_mysql_image gcr.io/parabolic-wall-323414/final_image
docker push gcr.io/parabolic-wall-323414/final_image
```

**Deploy on Compute Engine:**
```bash
gcloud compute instances create-with-container mysqlvm \
    --container-image gcr.io/parabolic-wall-323414/final_image
```

---

### Step 5: Replicate to BigQuery

With MySQL running on GCP, the final step is getting the `bq_data` table into BigQuery. This can be done with:

- **BigQuery Data Transfer Service** — scheduled transfers from MySQL
- **Cloud Composer (Airflow)** — orchestrate the ETL pipeline
- **Custom script** — using the BigQuery API or `bq` command-line tool

---

## What I Learned

- **Docker for data engineering** — containerizing databases makes them reproducible and easy to share
- **SQL at scale** — stored procedures and UDFs are powerful for data generation and transformation
- **Data modeling trade-offs** — normalized schemas for transactions vs. denormalized for analytics
- **GCP integration** — moving data between Compute Engine, Container Registry, and BigQuery
- **End-to-end pipeline thinking** — from raw data to analytics-ready tables

---

## Files in This Repo

```
.
├── docker-compose.yml      # Spins up MySQL + Adminer
├── .env                    # Database credentials and ports
├── .gitignore              # Files to ignore in version control
├── setup.sh                # One-command setup script
├── mysql/
│   ├── Dockerfile          # Custom MySQL image
│   └── data.sql            # Initial schema
└── scripts/
    ├── udf.sql             # User-defined functions for random data
    ├── store_procedure.sql # Bulk insertion procedure
    ├── populate_data.sql   # Calls the procedure to fill tables
    ├── modeling_data.sql   # Adds foreign keys
    └── to_bigquery.sql     # Final transformation for BigQuery
```

---

## Useful Commands

```bash
# Quick setup (recommended)
chmod +x setup.sh && ./setup.sh

# Start containers only
docker-compose up -d

# Stop and remove everything (including data)
docker-compose down -v

# View logs
docker-compose logs -f mysql

# Connect to MySQL directly
docker-compose exec mysql mysql -uroot -ppassword

# Quick data preview
docker-compose exec mysql mysql -uroot -ppassword -e "SELECT COUNT(*) FROM mydb.bq_data;"
```

---

Feel free to open an issue or PR if you see something that could be improved. This was a learning project and I'm always looking to make it better.