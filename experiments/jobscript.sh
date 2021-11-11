#!/bin/sh
#$ -N wmc
#$ -cwd
#$ -pe sharedmem 8
#$ -l h_rt=48:00:00
#$ -l h_vmem=8G

. /etc/profile.d/modules.sh
module load phys/compilers/gcc/10.2.0
module load cmake/3.5.2
module load roslin/python/3.8.1
module load roslin/boost/1.70.0

ulimit -c 0
lscpu > cpuinfo.txt
make -j 8
