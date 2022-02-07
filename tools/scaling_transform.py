import csv
from collections import defaultdict
from typing import DefaultDict, Dict, List, Tuple

TIMEOUT = 500

data: DefaultDict[Tuple[str, str], DefaultDict[str, List[float]]] = defaultdict(lambda: defaultdict(list))
with open('../results/regular1.csv') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        if float(row['time']) >= TIMEOUT or row['answer'] != '':
            data[(row['algorithm'], row['clause_factor'])][row['treewidth']].append(min(float(row['time']), TIMEOUT))

for (algorithm, mu), points in data.items():
    with open('../results/processed/{}-{}.csv'.format(algorithm, mu), 'w') as csvfile:
        writer = csv.writer(csvfile)
        for treewidth, times in points.items():
            writer.writerow(['', treewidth] + [str(t) for t in times])
