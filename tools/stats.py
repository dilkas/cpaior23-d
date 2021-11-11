import csv
import glob
import subprocess

data = []
fieldnames = set()
for filename in glob.glob('benchmarks/bayes/*.cnf'):
    row = {}
    with open(filename) as instance:
        header = instance.readline().split()
        row['variables'] = header[2]
        row['clauses'] = header[3]
        row['literals'] = 0
        row['equal_weights'] = 0
        row['deterministic'] = 0
        for line in instance:
            if not line.startswith('c'):
                row['literals'] += len(line.split()) - 1
            elif line.startswith('c weights'):
                weights = line.split()[2:]
                assert len(weights) == 2 * int(row['variables'])
                for i in range(0, len(weights), 2):
                    if weights[i] == weights[i+1]:
                        row['equal_weights'] += 1
                    elif (float(weights[i]) == 0 and float(weights[i+1]) == 1 or
                          float(weights[i]) == 1 and float(weights[i+1]) == 0):
                        row['zero_one'] += 1
    with open(filename[:filename.rindex('.')] + '.tw') as f:
        row['tw'] = f.read().split()[-1]
    fieldnames |= set(row.keys())
    data.append(row)

with open('stats.csv', 'w') as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    for d in data:
        writer.writerow(d)
