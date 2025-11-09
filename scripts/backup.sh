#!/bin/bash
mkdir -p plots_backup
rsync -a --delete plots/ plots_backup/

mkdir -p tables_backup
rsync -a --delete tables/ tables_backup/