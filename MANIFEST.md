# MANIFEST - Environment Specifications

## 1. System Overview

### CPU
- **Model:** Intel Core i7-11800H
- **Architecture:** x86_64
- **Cores:** 8 physical cores
- **Generation:** 11th Gen Intel Core (Tiger Lake-H)

### Memory
- **Total RAM:** 32 GB
- **Type:** DDR4
- **Used during tests:** <1 GB

### Operating System
- **HostbOS:** Windows 11 (x86_64)
- **Virtualization:** Docker Desktop (WSL2 backend)
- **Container OS:** Debian 13 (Bookworm)

## 2. Docker Configuration

- **Docker Version:** 28.5.1  
- **Image Name:** `pg17-hll` *(custom built)*  
- **Base Image:** `postgres:17`  
- **Image ID:** `sha256:ddecbf868f4aa14b24ee8c8639e3bcaa7f8ab2c286b269e05c9a2f620fc1bbf0`

### Resource Limits (`docker-compose.yml`)
```yaml
mem_limit: 2g      # 2 GB RAM limit
cpus: '1.0'        # 1 full CPU core
shm_size: 1g       # 1 GB shared memory
```

## 3. PostgreSQL Configuration

- **Version:** 17.6 (Debian 17.6-2.pgdg13+1)
- **Platform:** x86_64-pc-linux-gnu
- **Compiler:** gcc (Debian 14.2.0-19) 14.2.0
- **Architecture:** 64-bit

### HLL Extension
```
Name: hll
Version: 2.19
Schema: public
Comment: type for storing hyperloglog data
```

---

## 4. Python Environment

Python 3.12.10

### Required Packages
```
numpy
pandas
matplotlib
matplotlib-inline
seaborn
```
