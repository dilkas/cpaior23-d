#!/usr/bin/env python3

# Translate WMC instances from the MC competition format to the Cachet/miniC2D
# formats.
#
# Weights are normalised so that either w(x) + w(~x) = 1 or w(x) = w(~x) = 1
# for all variables x. This normalisation is necessary for the Cachet format.

import os

DATA_DIR = "data/benchmarks/mc2022"

for filename in os.listdir(DATA_DIR):
    if "cachet" in filename or "minic2d" in filename:
        continue
    cachet = []
    minic2d = []
    weights = {}
    with open(DATA_DIR + "/" + filename) as instance:
        for line in instance:
            if not line.startswith("c"):
                cachet.append(line)
                minic2d.append(line)
            elif line.startswith("c p weight"):
                words = line.split()
                weights[int(words[3])] = float(words[4])

    minic2d_weights = []
    for variable in range(1, max(weights.keys()) + 1):
        positive_weight = weights[variable]
        negative_weight = weights[-variable]
        if positive_weight == 1 and negative_weight == 1:
            cachet.append("w {} -1\n".format(variable))
        else:
            new_positive_weight = positive_weight / (positive_weight + negative_weight)
            new_negative_weight = negative_weight / (positive_weight + negative_weight)
            weights[variable] = new_positive_weight
            weights[-variable] = new_negative_weight
            cachet.append("w {} {}\n".format(variable, new_positive_weight))
        minic2d_weights += [str(weights[variable]), str(weights[-variable])]
    minic2d.append("c weights " + " ".join(minic2d_weights) + "\n")

    with open(DATA_DIR + "/" + filename + ".cachet.cnf", "w") as output:
        output.writelines(cachet)
    with open(DATA_DIR + "/" + filename + ".minic2d.cnf", "w") as output:
        output.writelines(minic2d)
