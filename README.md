Dilkas P. (2023) **Generating Random Instances of Weighted Model Counting: An Empirical Analysis with Varying Primal Treewidth**. CPAIOR 2023.

# How to Run

* Run `python tools/generate.py` to generate random WMC instances (modify the script to choose what kind of instances to generate).
* In the `experiments` directory, run
  * `make sat` to check the satisfiability of the instances,
  * `make tw` to estimate their treewidth,
  * and `make` to run the WMC algorithms.
* Run `python tools/parse.py` to parse the experimental data into a CSV file.
* Modify and use parts of `tools/analyse.R` to generate plots.

The original experiments were conducted with:
* `gcc 10.2.0`
* `cmake 3.5.2`
* `python 3.8.1`

# Experimental Results (in `results/`)

* Experiment 1 (Figure 1): `satisfiability.csv` (experimental data in `satisfiability/`)
* Experiment 2 (Figures 2 and 3): `processed.csv` (for ESA), `regular1.csv` (for everything else)
* Experiment 3 (the left-hand-side of Figure 4): `regular2.csv`
* Experiment 4 (the right-hand-side of Figure 4): `regular3.csv`
* Section 5.2 (Figure 5): `benchmark_runtime.csv`
