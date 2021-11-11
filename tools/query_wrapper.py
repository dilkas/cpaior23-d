import argparse
import resource
import subprocess

SOFT_MEMORY_LIMIT = 0.9  # As a proportion of the hard limit

C2D = ['deps/c2d_linux', '-in']
D4 = ['deps/d4']
QUERY = 'deps/query-dnnf/query-dnnf'

parser = argparse.ArgumentParser(
    description=
    'Run c2d/d4 and then query-dnnf to perform WMC inference'
)
parser.add_argument('algorithm', choices=['c2d', 'd4'], metavar='algorithm', help='a d-DNNF compilation algorithm (c2d or d4)')
parser.add_argument('instance', metavar='instance', help='a WMC instance')
parser.add_argument(
    '-m',
    dest='memory',
    help='the maximum amount of virtual memory available to query-dnnf (in GiB)'
)

args = parser.parse_args()
if args.algorithm == 'c2d':
    command = C2D + [args.instance]
else:
    command = D4 + [args.instance, '-out=' + args.instance + '.nnf']

if args.memory:
    mem = int(args.memory) * 1024**3
    c2d = subprocess.Popen(command, preexec_fn=lambda: resource.setrlimit(
        resource.RLIMIT_AS,
        (int(SOFT_MEMORY_LIMIT * mem), mem)))
    c2d.wait()
    process = subprocess.Popen(QUERY, stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE,
                               preexec_fn=lambda: resource.setrlimit(
                                   resource.RLIMIT_AS,
                                   (int(SOFT_MEMORY_LIMIT * mem), mem)))
else:
    c2d = subprocess.Popen(command)
    c2d.wait()
    process = subprocess.Popen(QUERY,
                               stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE)

output, _ = process.communicate('load {}.nnf\nw {}.weights\nmc'.format(
    args.instance, args.instance).encode())
process.wait()
print("ANSWER:", float(output.decode('utf-8').split()[-1]))
