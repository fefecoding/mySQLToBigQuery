#!/bin/bash

# MySQL to BigQuery Pipeline - Setup Script
# This script automates the setup process for the data pipeline

set -e

echo "🚀 MySQL to BigQuery Data Pipeline Setup"
echo "========================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop or the Docker daemon."
    exit 1
fi

# Step 1: Build and start containers
echo "📦 Building Docker containers..."
docker-compose up -d --build

echo "⏳ Waiting for MySQL to be ready..."
sleep 10

# Check if MySQL is ready
max_retries=30
retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if docker-compose exec -T mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo "✅ MySQL is ready!"
        break
    fi
    echo "   Waiting for MySQL... ($retry_count/$max_retries)"
    sleep 2
    retry_count=$((retry_count + 1))
done

if [ $retry_count -eq $max_retries ]; then
    echo "❌ MySQL failed to start. Check logs with: docker-compose logs mysql"
    exit 1
fi

# Step 2: Load UDFs
echo "📝 Loading User-Defined Functions (UDFs)..."
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/udf.sql

# Step 3: Load stored procedures
echo "📝 Loading stored procedures..."
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/store_procedure.sql

# Step 4: Generate mock data
echo "🎲 Generating mock data (this may take a moment)..."
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/populate_data.sql

# Step 5: Add foreign keys
echo "🔗 Adding foreign key constraints..."
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/modeling_data.sql

# Step 6: Create BigQuery-ready table
echo "🔄 Creating BigQuery-ready table..."
docker-compose exec -T mysql mysql -uroot -ppassword < scripts/to_bigquery.sql

echo ""
echo "✅ Setup complete!"
echo ""
echo "📊 Database info:"
echo "   - Host: localhost:3306"
echo "   - Database: mydb"
echo "   - Username: user"
echo "   - Password: password"
echo ""
echo "🌐 Adminer UI: http://localhost:8080"
echo "   - System: MySQL"
echo "   - Username: user"
echo "   - Password: password"
echo "   - Database: mydb"
echo ""
echo "🔍 Quick test - View the BigQuery-ready data:"
echo "   docker-compose exec mysql mysql -uroot -ppassword -e 'SELECT * FROM mydb.bq_data LIMIT 5;'"
echo ""
echo "🧹 To clean up everything:"
echo "   docker-compose down -v"