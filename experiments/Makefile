TIMEOUT = 500
MAX_MEMORY = 8 # in GB
MAX_MEMORY_KB = 7549747 # 90% of MAX_MEMORY

CACHET = ../deps/cachet/cachet-wmc
WRAPPER = python ../tools/query_wrapper.py -m $(MAX_MEMORY)
MINIC2D = ../deps/miniC2D/bin/linux/miniC2D -i -W -c
MINISAT = LD_LIBRARY_PATH="$$LD_LIBRARY_PATH":../deps/minisat/lib ../deps/minisat/bin/minisat
HTD = ../deps/DPMC/lg/solvers/htd-master/bin/htd_main --opt width --strategy challenge --preprocessing full --output width --iterations 1
JDRASIL = ../deps/Jdrasil/tw-exact

LG = ../deps/DPMC/lg/build/lg \"../deps/DPMC/lg/solvers/htd-master/bin/htd_main --opt width --iterations 1 --strategy challenge --print-progress --preprocessing full\"
DPMC = ../deps/DPMC/DMC/dmc --jf=- --pf=1e-3 --jw=$(TIMEOUT)

LIMIT = ulimit -t $(TIMEOUT) -c 0
RUN = $(LIMIT) && ulimit -Sv $(MAX_MEMORY_KB) && /usr/bin/time -v

all: $(addsuffix /TARGET,$(basename $(basename $(wildcard data/*.cachet.cnf))))

# Same as 'all' but fails whenever an algorithm fails (e.g., from running out of time or memory)
sensitive: $(addsuffix /TARGETTWO,$(basename $(basename $(wildcard data/*.cachet.cnf))))

# Calculate treewidth
tw: $(addsuffix /TREEWIDTH,$(basename $(basename $(wildcard data/*.cachet.cnf))))

# Exact treewidth
exacttw: $(addsuffix /EXACTTREEWIDTH,$(basename $(basename $(wildcard data/*.cachet.cnf))))

# Check satisfiability
sat: $(addsuffix /SAT,$(basename $(basename $(wildcard data/*.cachet.cnf))))

# Compute statistics about Bayesian network WMC encodings
benchmarks: $(addsuffix /BENCHMARK,$(basename $(wildcard data/*.cnf)))

data/%/TARGET:
	-cnf="data/$*.cachet.cnf" && $(RUN) -f "%es" bash -c "$(LG) < $$cnf | $(DPMC) --cf=$$cnf" &> results/$*.dpmc
	-$(RUN) $(CACHET) data/$*.cachet.cnf &> results/$*.cachet
	-$(LIMIT) && /usr/bin/time -v $(WRAPPER) c2d data/$*.minic2d.cnf &> results/$*.c2d
	-$(LIMIT) && /usr/bin/time -v $(WRAPPER) d4 data/$*.minic2d.cnf &> results/$*.d4
	-$(RUN) $(MINIC2D) data/$*.minic2d.cnf &> results/$*.minic2d

data/%/TARGETTWO:
	cnf="data/$*.cachet.cnf" && $(RUN) -f "%es" bash -c "$(LG) < $$cnf | $(DPMC) --cf=$$cnf" &> results/$*.dpmc
	$(RUN) $(CACHET) data/$*.cachet.cnf &> results/$*.cachet
	$(LIMIT) && /usr/bin/time -v $(WRAPPER) c2d data/$*.minic2d.cnf &> results/$*.c2d
	$(LIMIT) && /usr/bin/time -v $(WRAPPER) d4 data/$*.minic2d.cnf &> results/$*.d4
	$(RUN) $(MINIC2D) data/$*.minic2d.cnf &> results/$*.minic2d

%/TREEWIDTH:
	$(HTD) < $*.gr &> $*.tw

%/EXACTTREEWIDTH:
	$(JDRASIL) < $*.gr &> $*.exacttw

%/SAT:
	-$(MINISAT) $*.minic2d.cnf &> $*.sat

%/BENCHMARK:
	python ../tools/primal_graph.py $*.cnf
	$(HTD) < $*.gr &> $*.tw
