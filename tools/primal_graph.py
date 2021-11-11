import argparse

parser = argparse.ArgumentParser(
    description=
    'Construct the primal graph of a given CNF formula'
)
parser.add_argument('formula', metavar='formula', help='a CNF formula file')
args = parser.parse_args()

edges = set()
with open(args.formula) as f:
    num_variables = f.readline().split()[-2]
    for line in f:
        if not line.startswith('c'):
            tokens = line.split()
            for i in range(len(tokens) - 1):
                for j in range(i + 1, len(tokens) - 1):
                    x = abs(int(tokens[i]))
                    y = abs(int(tokens[j]))
                    edges.add((min(x, y), max(x, y)))
with open(args.formula[:args.formula.rindex('.')] + '.gr', 'w') as f:
    f.write('p tw ' + num_variables + ' ' + str(len(edges)) + '\n')
    for edge in edges:
        f.write(str(edge[0]) + ' ' + str(edge[1]) + '\n')
