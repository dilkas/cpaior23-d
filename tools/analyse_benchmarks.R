source("util.R")

TIMEOUT <- 3600

data <- read_data("../results/benchmark_runtime.csv")

plot_with_sd(data, "variables", "Treewidth")

ggplot(data, aes(treewidth, time, colour = algorithm)) + geom_point() + scale_x_log10()
