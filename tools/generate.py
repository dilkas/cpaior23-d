import glob
import os
import random
import subprocess

VERBOSE_MODE = False
probabilities = [x / 100 for x in range(1, 100)]
OUTPUT_DIR = "data/"


class InstanceGenerator:
    instance_count = 0

    def __init__(
        self,
        num_variables,
        clause_factor,
        literal_factor,
        repetitiveness,
        prop_deterministic,
        prop_equal,
        kcnf,
    ):
        self.num_variables = num_variables
        self.clause_factor = clause_factor
        self.literal_factor = literal_factor
        self.repetitiveness = repetitiveness
        self.prop_deterministic = prop_deterministic
        self.prop_equal = prop_equal
        self.kcnf = kcnf
        assert prop_deterministic + prop_equal <= 1

    def random_partition(self, total, count):
        if self.kcnf:
            return [int(round(self.literal_factor))] * count
        partition = []
        while True:
            bars = sorted(random.sample(range(1, total), count - 1))
            partition = (
                [bars[0]]
                + [bars[i] - bars[i - 1] for i in range(1, len(bars))]
                + [total - bars[-1]]
            )
            if all(x <= self.num_variables for x in partition):
                if VERBOSE_MODE:
                    print("Partition:", partition)
                return partition

    def new_literal(self, previous_variables, primal_graph):
        if len(previous_variables) == 0:
            return random.choice(range(1, self.num_variables + 1))
        denominator = sum(
            len(primal_graph[v - 1] - set(previous_variables))
            for v in previous_variables
        )
        choices = list(set(range(1, self.num_variables + 1)) - set(previous_variables))
        if denominator == 0:
            return random.choice(choices)

        weights = [
            (1 - self.repetitiveness) / (self.num_variables - len(previous_variables))
        ] * len(choices)
        for i in range(len(choices)):
            weights[i] += (
                self.repetitiveness
                * len(primal_graph[choices[i] - 1] & set(previous_variables))
                / denominator
            )
        if VERBOSE_MODE:
            print("Choices for a new variable:", choices)
            print("Probability distribution:", weights)
        return random.choices(choices, weights=weights)[0]

    def generate_instance(self):
        literals_per_clause = self.random_partition(
            int(self.num_variables * self.clause_factor * self.literal_factor),
            int(self.num_variables * self.clause_factor),
        )
        clauses = []
        primal_graph = []
        for _ in range(self.num_variables):
            primal_graph.append(set())
        for literal_count in literals_per_clause:
            literals = []
            for _ in range(literal_count):
                l = self.new_literal(literals, primal_graph)
                for m in literals:
                    primal_graph[l - 1].add(m)
                    primal_graph[m - 1].add(l)
                literals.append(l)
                if VERBOSE_MODE:
                    print("New variable:", l)
            clauses.append([x if random.randint(0, 1) > 0 else -x for x in literals])
            if VERBOSE_MODE:
                print("New clause:", clauses[-1])
        self.instance_count += 1
        return clauses

    def output_graph(self, clauses):
        edges = set(
            (min(abs(clause[i]), abs(clause[j])), max(abs(clause[i]), abs(clause[j])))
            for clause in clauses
            for i in range(len(clause) - 1)
            for j in range(i + 1, len(clause))
        )
        s = "p tw " + str(self.num_variables) + " " + str(len(edges)) + "\n"
        for edge in edges:
            s += str(edge[0]) + " " + str(edge[1]) + "\n"
        return s

    def output_dot_graph(self, clauses):
        edges = set(
            (min(abs(clause[i]), abs(clause[j])), max(abs(clause[i]), abs(clause[j])))
            for clause in clauses
            for i in range(len(clause) - 1)
            for j in range(i + 1, len(clause))
        )
        s = 'graph {\nnode[label=""];\n'
        for edge in edges:
            s += str(edge[0]) + " -- " + str(edge[1]) + ";\n"
        return s + "}\n"

    def write_dot_file(self, clauses):
        with open(str(self) + ".dot", "w") as f:
            f.write(self.output_dot_graph(clauses))

    def generate_weights(self):
        # Partition variables into deterministic, equal-weighted, and probabilistic (in that order)
        variables = list(range(1, self.num_variables + 1))
        random.shuffle(variables)
        if VERBOSE_MODE:
            print("Variable shuffle:", variables)
        first_equal = int(self.prop_deterministic * self.num_variables)
        first_probabilistic = first_equal + int(self.prop_equal * self.num_variables)
        weights = {}
        for i in range(first_equal):
            weights[variables[i]] = random.randint(0, 1)
            if VERBOSE_MODE:
                print(
                    "Assigning a deterministic weight",
                    weights[variables[i]],
                    "to variable",
                    variables[i],
                )
        for i in range(first_equal, first_probabilistic):
            weights[variables[i]] = 0.5
            if VERBOSE_MODE:
                print("Assigning a 0.5/0.5 weight to variable", variables[i])
        for i in range(first_probabilistic, len(variables)):
            weights[variables[i]] = random.choice(probabilities)
            if VERBOSE_MODE:
                print(
                    "Assigning a random weight",
                    weights[variables[i]],
                    "to variable",
                    variables[i],
                )
        assert len(weights) == self.num_variables
        return weights

    def output_cachet(self, clauses, weights):
        s = "p cnf " + str(self.num_variables) + " " + str(len(clauses)) + "\n"
        for clause in clauses:
            s += " ".join([str(l) for l in clause]) + " 0\n"
        for variable, weight in weights.items():
            s += "w " + str(variable) + " " + str(weight) + "\n"
        return s

    def output_minic2d(self, clauses, weights):
        s = "p cnf " + str(self.num_variables) + " " + str(len(clauses)) + "\n"
        for clause in clauses:
            s += " ".join([str(l) for l in clause]) + " 0\n"
        weights_line = "c weights"
        for variable in range(1, self.num_variables + 1):
            if weights[variable] == -1:
                weights_line += " 1 1"
            else:
                weights_line += (
                    " " + str(weights[variable]) + " " + str(1 - weights[variable])
                )
        return s + weights_line + "\n"

    def __str__(self):
        return "-".join(
            [
                str(s)
                for s in [
                    self.num_variables,
                    self.clause_factor,
                    self.literal_factor,
                    self.repetitiveness,
                    self.prop_deterministic,
                    self.prop_equal,
                    self.instance_count,
                ]
            ]
        )

    def write_files(self, clauses, weights):
        with open(OUTPUT_DIR + str(self) + ".minic2d.cnf", "w") as f:
            f.write(self.output_minic2d(clauses, weights))
        with open(OUTPUT_DIR + str(self) + ".minic2d.cnf.weights", "w") as f:
            f.write(self.output_weights(weights))
        with open(OUTPUT_DIR + str(self) + ".cachet.cnf", "w") as f:
            f.write(self.output_cachet(clauses, weights))
        with open(OUTPUT_DIR + str(self) + ".gr", "w") as f:
            f.write(self.output_graph(clauses))

    def output_weights(self, weights):
        s = ""
        for variable in range(1, self.num_variables + 1):
            if weights[variable] != -1:
                if weights[variable] == 0:
                    s += str(variable) + " 0\n"
                elif weights[variable] == 1:
                    s += "-" + str(variable) + " 0\n"
                else:
                    s += str(variable) + " " + str(weights[variable]) + "\n"
                    s += "-" + str(variable) + " " + str(1 - weights[variable]) + "\n"
        return s


def count_sat():
    count = 0
    for filename in glob.glob("data/*.sat"):
        with open(filename) as f:
            text = f.read()
            is_sat = text.split()[-1] != "UNSATISFIABLE"
        if is_sat:
            count += 1
        else:
            for filename2 in glob.glob(filename[: filename.rindex(".") + 1] + "*"):
                os.remove(filename2)
    return count


def generate_sat_instances(generator, repeats):
    while repeats > 0:
        for f in glob.glob("data/*.sat"):
            os.remove(f)
        for _ in range(repeats):
            clauses = generator.generate_instance()
            weights = generator.generate_weights()
            generator.write_files(clauses, weights)
            subprocess.run(["make", "data/" + str(generator) + "/SAT"])
        repeats -= count_sat()


def scalability_experiment(clause_factor, literal_factor, kcnf):
    for n in range(10, 1000):
        generator = InstanceGenerator(n, clause_factor, literal_factor, 0, 0, 0, kcnf)
        generate_sat_instances(generator, 10)
        make = subprocess.Popen(["make", "sensitive"])
        make.wait()
        os.system("rm data/*")
        if make.returncode != 0:
            break


# Satisfiability heatmap (for k-CNFs)
# for clause_factor in range(-5, 6):
#     for literal_factor in range(1, 6):
#         for repetitiveness in range(101):
#             generator = InstanceGenerator(100, 2.5 * 2**(clause_factor/2),
#                                           literal_factor, repetitiveness / 100, 0, 0, True)
#             for _ in range(10):
#                 clauses = generator.generate_instance()
#                 weights = generator.generate_weights()
#                 generator.write_files(clauses, weights)

# scalability_experiment(2.5, 3, True)
# scalability_experiment(0.625, 5, False)

# Density & treewidth for k-CNF
# for num_variables in [35, 70]:
#     for repetitiveness in range(0, 51):
#         for density in range(10, 46, 3):
#             generator = InstanceGenerator(num_variables, density / 10, 3, repetitiveness / 100,
#                                           0, 0, True)
#             generate_sat_instances(generator, 100)

# Determinism for k-CNF
# for determinism in range(101):
#         generator = InstanceGenerator(70, 2.2, 3, 0, determinism / 100, 0, True)
#         generate_sat_instances(generator, 100)

# Equality for k-CNF
for prop_equal in range(101):
    generator = InstanceGenerator(70, 2.2, 3, 0, 0, prop_equal / 100, True)
    generate_sat_instances(generator, 100)

# A small test
# generator = InstanceGenerator(5, 0.6, 3, 0.3, 0.4, 0.2, False)
# clauses = generator.generate_instance()
# weights = generator.generate_weights()
# generator.write_files(clauses, weights)
