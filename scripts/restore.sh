#!/bin/bash
mkdir -p plots
rsync -a --delete plots_backup/ plots/

mkdir -p tables
rsync -a --delete tables_backup/ tables/