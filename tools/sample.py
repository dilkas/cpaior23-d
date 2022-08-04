#!/usr/bin/env python3

import glob
import random
import shutil

PROPORTION = 0.1

names = [f[: -len("cachet.cnf")] for f in glob.glob("data/regular1/*.cachet.cnf")]
for name in random.sample(names, int(PROPORTION * len(names))):
    for f in glob.glob(name + "*"):
        shutil.copy(f, "data/regular1-subset/")
