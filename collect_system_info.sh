#!/bin/bash

# System Information Collection Script
# Run this to gather all hardware/software specs for your paper

echo "=================================================="
echo "COL868 HLL Benchmark - System Information"
echo "=================================================="
echo ""

echo ">>> Collecting system information..."
echo ""

# Create output file
OUTPUT="system_info.txt"
> $OUTPUT

echo "================================" >> $OUTPUT
echo "HARDWARE SPECIFICATIONS" >> $OUTPUT
echo "================================" >> $OUTPUT
echo "" >> $OUTPUT

echo "CPU Information:" >> $OUTPUT
docker exec pgdb cat /proc/cpuinfo | grep "model name" | head -1 >> $OUTPUT
docker exec pgdb cat /proc/cpuinfo | grep "cpu cores" | head -1 >> $OUTPUT
docker exec pgdb cat /proc/cpuinfo | grep "cpu MHz" | head -1 >> $OUTPUT
echo "" >> $OUTPUT

echo "Memory Information:" >> $OUTPUT
docker exec pgdb free -h | grep -E "Mem|Swap" >> $OUTPUT
echo "" >> $OUTPUT

echo "Disk Information:" >> $OUTPUT
docker exec pgdb df -h / >> $OUTPUT
echo "" >> $OUTPUT

echo "================================" >> $OUTPUT
echo "SOFTWARE VERSIONS" >> $OUTPUT
echo "================================" >> $OUTPUT
echo "" >> $OUTPUT

echo "Operating System:" >> $OUTPUT
docker exec pgdb cat /etc/os-release | grep -E "PRETTY_NAME|VERSION" >> $OUTPUT
echo "" >> $OUTPUT

echo "PostgreSQL Version:" >> $OUTPUT
docker exec pgdb psql -U myuser -d mydb -c "SELECT version();" >> $OUTPUT
echo "" >> $OUTPUT

echo "HLL Extension:" >> $OUTPUT
docker exec pgdb psql -U myuser -d mydb -c "SELECT * FROM pg_available_extensions WHERE name='hll';" >> $OUTPUT
echo "" >> $OUTPUT

echo "PostgreSQL Configuration:" >> $OUTPUT
docker exec pgdb psql -U myuser -d mydb -c "SHOW shared_buffers; SHOW work_mem; SHOW jit;" >> $OUTPUT
echo "" >> $OUTPUT

echo "================================" >> $OUTPUT
echo "DOCKER INFORMATION" >> $OUTPUT
echo "================================" >> $OUTPUT
echo "" >> $OUTPUT

echo "Docker Version:" >> $OUTPUT
docker --version >> $OUTPUT
echo "" >> $OUTPUT

echo "Container Status:" >> $OUTPUT
docker ps --filter name=pgdb >> $OUTPUT
echo "" >> $OUTPUT

echo "================================" >> $OUTPUT
echo "PYTHON ENVIRONMENT" >> $OUTPUT
echo "================================" >> $OUTPUT
echo "" >> $OUTPUT

echo "Python Version:" >> $OUTPUT
python3 --version >> $OUTPUT
echo "" >> $OUTPUT

echo "Installed Packages:" >> $OUTPUT
pip list | grep -E "pandas|matplotlib|seaborn|numpy" >> $OUTPUT
echo "" >> $OUTPUT

echo "================================" >> $OUTPUT
echo "COLLECTION TIMESTAMP" >> $OUTPUT
echo "================================" >> $OUTPUT
date >> $OUTPUT
echo "" >> $OUTPUT

# Display to console
cat $OUTPUT

echo ""
echo "=================================================="
echo "✅ System information saved to: $OUTPUT"
echo "=================================================="
echo ""
echo "Use this information to update your paper:"
echo "1. Section 3.1 (Experimental Setup)"
echo "2. README.md (Environment section)"
echo ""
echo "Next steps:"
echo "1. Run benchmark: docker exec -it pgdb psql -U myuser -d mydb -f benchmark_fast.sql"
echo "2. Copy results: docker cp pgdb:/tmp/results_*.csv ./"
echo "3. Generate plots: python plot_results.py"
echo ""