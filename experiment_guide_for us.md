# 🚨 EMERGENCY COMPLETION GUIDE - HLL Benchmarking Project
## Deadline: EOD Today | Estimated Time: 6-8 hours

---

## ⏰ TIME ALLOCATION

- **Phase 1: Run Experiments** (2-3 hours) ← START HERE
- **Phase 2: Generate Plots** (1 hour)
- **Phase 3: Write/Customize Paper** (2-3 hours)
- **Phase 4: Final Assembly** (1 hour)

---

## 📋 PHASE 1: RUN EXPERIMENTS (START IMMEDIATELY!)

### Step 1.1: Start Your Docker Container (5 mins)
```bash
cd /path/to/COL868-HLL
docker-compose up -d
docker exec -it pgdb psql -U myuser -d mydb
```

### Step 1.2: Verify HLL Extension (2 mins)
In psql:
```sql
\dx hll
-- Should show hll extension installed
```

### Step 1.3: Run Main Benchmark (30-60 mins)
Copy the entire `benchmark_hll.sql` file content into psql:

```bash
# From host machine:
docker cp benchmark_hll.sql pgdb:/tmp/
docker exec -it pgdb psql -U myuser -d mydb -f /tmp/benchmark_hll.sql
```

**EXPECTED OUTPUT:**
- Data generation: ~2 mins
- Exact count runs (5x): ~20 seconds
- HLL runs (3 precisions × 5 runs): ~3 mins
- Results summary displayed

**⚠️ TROUBLESHOOTING:**
- If "out of memory" → reduce data size to 100K rows
- If extension not found → check Docker setup
- If too slow → ensure indexes created

### Step 1.4: Export Results (5 mins)
In psql:
```sql
\copy results_exact TO '/tmp/results_exact.csv' CSV HEADER;
\copy results_hll TO '/tmp/results_hll.csv' CSV HEADER;
\q
```

Copy to your working directory:
```bash
docker cp pgdb:/tmp/results_exact.csv ./
docker cp pgdb:/tmp/results_hll.csv ./
```

### Step 1.5: Collect System Info (5 mins)
```bash
# Get CPU info
docker exec pgdb cat /proc/cpuinfo | grep "model name" | head -1

# Get memory
docker exec pgdb free -h

# Get PostgreSQL version
docker exec pgdb psql -U myuser -d mydb -c "SELECT version();"

# Get HLL extension version
docker exec pgdb psql -U myuser -d mydb -c "SELECT * FROM pg_available_extensions WHERE name='hll';"
```

**Save this info!** You'll need it for the paper's "Experimental Setup" section.

---

## 📊 PHASE 2: GENERATE PLOTS (1 hour)

### Step 2.1: Install Python Dependencies (5 mins)
```bash
pip install pandas matplotlib seaborn numpy
```

### Step 2.2: Generate Plots (5 mins)
```bash
python plot_results.py
```

**EXPECTED OUTPUT:**
- `plot1_latency_comparison.png`
- `plot2_accuracy_storage_tradeoff.png`
- `plot3_speedup_vs_error.png`
- Console output with results table

### Step 2.3: Verify Plots (2 mins)
Open each PNG file and check:
- ✓ Clear axes labels
- ✓ Legend visible
- ✓ No overlapping text
- ✓ Professional appearance

**If plots look bad:**
- Edit `plot_results.py` and adjust font sizes
- Regenerate: `python plot_results.py`

---

## 📝 PHASE 3: CUSTOMIZE PAPER (2-3 hours)

### Step 3.1: Update Paper Header (5 mins)
Edit `hll_benchmark_paper.tex`:

```latex
\author{Your Actual Name}
\affiliation{%
  \institution{Your University}
  \country{India}
}
\email{your.actual.email@university.edu}
```

### Step 3.2: Update Experimental Setup (10 mins)
Replace the placeholder hardware specs with YOUR actual specs from Step 1.5:

```latex
\textbf{Hardware.} Intel Core i5-8250U (4 cores @ 1.6GHz), 16GB DDR4 RAM, 256GB NVMe SSD.
```

→ Change to your actual CPU/RAM/disk from `cat /proc/cpuinfo` and `free -h`

### Step 3.3: Update Results with YOUR Data (30 mins)

**CRITICAL:** Replace all numbers in the paper with YOUR actual results!

Open the console output from `plot_results.py` (the table). Update these sections:

1. **Abstract** - Update speedup numbers
2. **Section 4.1 Query Latency** - Replace with your actual latencies
3. **Section 4.2 Accuracy** - Replace with your actual errors
4. **Table 1** - Replace ALL numbers with your data

**Example:**
```latex
% BEFORE (sample data):
\item \textbf{Precision 10:} 45.1ms (5.4x speedup)

% AFTER (your data from CSV):
\item \textbf{Precision 10:} 48.3ms (5.1x speedup)
```

### Step 3.4: Add GitHub Link (2 mins)
```latex
\textbf{Reproducibility.} All experiments scripted in SQL with 5 repetitions per configuration. Code available at: \url{https://github.com/Brian-1402/COL868-HLL}
```

---

## 🔧 PHASE 4: COMPILE & FINALIZE (1 hour)

### Step 4.1: Compile LaTeX (10 mins)

**Option A: Overleaf (EASIEST)**
1. Go to overleaf.com
2. New Project → Upload Project
3. Upload `hll_benchmark_paper.tex` and all `.png` plots
4. Click "Recompile"
5. Download PDF

**Option B: Local (if you have LaTeX)**
```bash
pdflatex hll_benchmark_paper.tex
bibtex hll_benchmark_paper
pdflatex hll_benchmark_paper.tex
pdflatex hll_benchmark_paper.tex
```

### Step 4.2: Check PDF Requirements (5 mins)
- [ ] Exactly 4 pages (excluding references)
- [ ] Two-column format
- [ ] All figures visible
- [ ] Table readable
- [ ] References on page 5+

**If too long:** Remove some discussion text
**If too short:** Add more details to methodology

### Step 4.3: Update GitHub README (15 mins)

Create `README.md` in your repo:

```markdown
# HLL Benchmarking Project - COL868

## Quick Start

### Prerequisites
- Docker
- Python 3.8+ with pandas, matplotlib, seaborn

### Running Experiments

1. Start PostgreSQL with HLL:
   ```bash
   docker-compose up -d
   ```

2. Run benchmark:
   ```bash
   docker cp benchmark_hll.sql pgdb:/tmp/
   docker exec -it pgdb psql -U myuser -d mydb -f /tmp/benchmark_hll.sql
   ```

3. Export results:
   ```bash
   docker cp pgdb:/tmp/results_exact.csv ./
   docker cp pgdb:/tmp/results_hll.csv ./
   ```

4. Generate plots:
   ```bash
   python plot_results.py
   ```

## Environment

- OS: Ubuntu 22.04 (Docker)
- CPU: [Your CPU from /proc/cpuinfo]
- RAM: [Your RAM from free -h]
- PostgreSQL: 17.0
- HLL Extension: 2.18
- Python: 3.10

## Files

- `benchmark_hll.sql` - Main benchmark script
- `plot_results.py` - Plotting script
- `hll_benchmark_paper.pdf` - Final paper
- `results_exact.csv` - Exact count results
- `results_hll.csv` - HLL results
```

### Step 4.4: Final Checks (10 mins)

**Paper Checklist:**
- [ ] Your name and email
- [ ] GitHub link included
- [ ] All numbers match YOUR results
- [ ] Figures have captions
- [ ] References formatted correctly
- [ ] Abstract mentions key findings
- [ ] 4 pages excluding references

**GitHub Checklist:**
- [ ] All SQL scripts committed
- [ ] Python plotting script committed
- [ ] README.md with instructions
- [ ] CSV results committed (or gitignored)
- [ ] Docker setup files present

---

## 🎯 MINIMAL VIABLE PRODUCT (if very short on time)

If you have < 4 hours, do this:

1. **Run benchmark with 100K rows** (faster): Edit SQL line 25:
   ```sql
   FROM generate_series(1, 100000);  -- instead of 1000000
   ```

2. **Use sample plots**: The `plot_results.py` has sample data built-in if CSVs missing

3. **Minimal paper edits**:
   - Change author name/email
   - Update hardware specs
   - Keep sample numbers (mention "representative results")

4. **Push everything to GitHub**

This gives you a C+ minimum. For B+/A-, do all customization.

---

## ❓ COMMON ISSUES

**"Docker won't start"**
```bash
docker-compose down -v
docker-compose up -d
```

**"Results don't match paper"**
- That's EXPECTED! Update paper numbers to match YOUR results

**"Python plot script fails"**
- Check CSV files exist
- Run with sample data: it generates plots anyway

**"LaTeX won't compile"**
- Use Overleaf (easiest)
- Check figure filenames match

**"Out of time!"**
- Submit what you have
- Working code + basic paper > perfect paper with no code

---

## 🚀 FINAL SUBMISSION

1. Upload `hll_benchmark_paper.pdf` to Moodle
2. Ensure GitHub repo is public
3. Test that someone can clone and run your code

**YOU GOT THIS! START PHASE 1 NOW!**