#!/bin/sh
#$ -N wmc
#$ -cwd
#$ -l h_rt=107:00:00
#$ -l h_vmem=32G

. /etc/profile.d/modules.sh
module load phys/compilers/gcc/10.2.0
module load cmake/3.5.2
module load roslin/python/3.8.1
module load roslin/boost/1.70.0

ulimit -c 0
lscpu > cpuinfo.txt
make
