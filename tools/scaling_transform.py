import csv
from collections import defaultdict
from pathlib import Path
from typing import DefaultDict, Dict, List, Tuple
import shutil
import subprocess

TIMEOUT = 500

data: DefaultDict[Tuple[str, str], List[Tuple[str, float]]] = defaultdict(list)
with open('../results/regular1.csv') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        if float(row['time']) >= TIMEOUT or row['answer'] != '':
            data[(row['algorithm'], row['clause_factor'])].append((row['treewidth'], min(float(row['time']), TIMEOUT)))

for (algorithm, mu), points in data.items():
    directory = '../results/processed/{}-{}'.format(algorithm, mu)
    Path(directory).mkdir(parents=True, exist_ok=True)
    shutil.copyfile('../deps/ESA/examples/lingeling/models.txt', directory + '/models.txt')
    with open(directory + '/configurations.txt', 'w') as config:
        config.write('fileName: runtimes.csv\n')
        config.write('algName: {}\n'.format(algorithm))
        config.write('instName: random instances with mu = {}\n'.format(mu))
        config.write('trainTestSplit: 0.3\n')
        config.write('alpha: 95\n')
        config.write('numBootstrapSamples: 1001\n')
        config.write('numPerInstanceBootstrapSamples: 21\n')
        config.write('statistic: median\n')
        config.write('perInstanceStatistic: median\n')
        config.write('modelFileName: models.txt\n')
        config.write('numObservations: 1\n')
        config.write('window: 101\n')
        config.write('runtimeCutoff: 500\n')
        config.write('logLevel: info\n')
    with open(directory + '/runtimes.csv', 'w') as csvfile:
        writer = csv.writer(csvfile)
        for treewidth, time in points:
            writer.writerow(['', treewidth, str(time)])
    p = subprocess.Popen(['sh', 'runESA.sh', '../' + directory], cwd='../deps/ESA')
    p.wait()
