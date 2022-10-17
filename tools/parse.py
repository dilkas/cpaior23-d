import csv
import glob
import os

DATA_DIR = "experiments/data"
RESULTS_DIR = "experiments/results"
OUTPUT_FILE = "results.csv"
PARSE_TREEWIDTH = False  # otherwise parses runtime


def get_instance_name(filename):
    return filename[filename.rindex("/") + 1 : filename.index(".")]


def parse_instance_name(name):
    parts = name.split("-")
    try:
        instance = {
            "instance": name,
            "num_variables": parts[0],
            "clause_factor": parts[1],
            "literal_factor": parts[2],
            "repetitiveness": parts[3],
            "prop_deterministic": parts[4],
            "prop_equal": parts[5],
        }
    except IndexError:
        instance = {"instance": name}

    if name in cnf_data:
        instance |= cnf_data[name]
    if name in sat_data:
        instance["sat"] = sat_data[name]
    if name in tw_data:
        instance["treewidth"] = tw_data[name]
    return instance


fieldnames = set()
cnf_data = {}
sat_data = {}
tw_data = {}

for cnf_file in glob.glob(DATA_DIR + "/*.cnf"):
    with open(cnf_file) as f:
        for line in f:
            if line.startswith("p"):
                words = line.split()
                cnf_data[get_instance_name(cnf_file)] = {
                    "variables": words[2],
                    "edges": words[3],
                }
                break

for sat_file in glob.glob(DATA_DIR + "/*.sat"):
    with open(sat_file) as f:
        sat_data[get_instance_name(sat_file)] = (
            1 if f.read().split()[-1] != "UNSATISFIABLE" else 0
        )

for tw_file in glob.glob(DATA_DIR + "/*.tw"):
    with open(tw_file) as f:
        try:
            tw = int(f.read().split()[-1])
        except IndexError:
            tw = None
        print(tw_file, tw)
        tw_data[get_instance_name(tw_file)] = tw

data = []
fieldnames = set()
if PARSE_TREEWIDTH:
    for instance in sat_data.keys() | tw_data.keys():
        data.append(parse_instance_name(instance))
        fieldnames |= set(data[-1].keys())
else:
    for solution_file in glob.glob(RESULTS_DIR + "/*"):
        instance2 = parse_instance_name(get_instance_name(solution_file))
        instance2["algorithm"] = solution_file[solution_file.rindex(".") + 1 :]
        print("Parsing", solution_file)
        with open(solution_file) as f:
            for line in f:
                words = line.lstrip().split()
                if line.lstrip().startswith("Elapsed"):
                    tokens = words[7].split(":")
                    instance2["time"] = float(tokens[-1])
                    if len(tokens) > 1:
                        instance2["time"] += 60 * int(tokens[-2])
                    if len(tokens) > 2:
                        instance2["time"] += 60**2 * int(tokens[-3])
                    break
                if line.lstrip().startswith("ANSWER:") and instance2["algorithm"] in [
                    "c2d",
                    "d4",
                ]:
                    instance2["answer"] = words[1]
                elif (
                    line.lstrip().startswith("Satisfying")
                    and instance2["algorithm"] == "cachet"
                ):
                    instance2["answer"] = words[2]
                elif line.lstrip().startswith("s wmc") and instance2["algorithm"] in [
                    "addmc",
                    "dpmc",
                ]:
                    instance2["answer"] = words[2]
                elif (
                    len(words) >= 2
                    and words[0] == "Count"
                    and instance2["algorithm"] == "minic2d"
                ):
                    try:
                        instance2["answer"] = float(words[1])
                    except:
                        pass
        data.append(instance2)
        fieldnames |= set(instance2.keys())

with open(OUTPUT_FILE, "w") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    for d in data:
        writer.writerow(d)
