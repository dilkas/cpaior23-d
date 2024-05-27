source("util.R")
require("ggpattern")

TIMEOUT <- 3600
NUM_CELLS <- 10

add_missing_data <- function(row) {
  new_data <- data.frame()
  for (algorithm in unique(data$algorithm)) {
    found <- data[data$algorithm == algorithm &
                    data$instance == row[["instance"]],]
    if (dim(found)[1] == 0) {
      row$algorithm <- algorithm
      row$time <- TIMEOUT
      row$answer <- NA
      new_data <- rbind(new_data, as.data.frame(row))
    }
  }
  new_data
}

find_min_time <- function(row) {
  min(data$time[data$instance == row[["instance"]]])
}

data <- read_data("../results/benchmark_runtime.csv")
data <- rbind(data, bind_rows(apply(
  data[data$algorithm == "\\textsc{Cachet}",], 1, add_missing_data)))
data$density <- as.numeric(data$edges) / as.numeric(data$variables)
data$tw_bin <- cut_number(as.numeric(data$treewidth), NUM_CELLS)
data$density_bin <- cut_number(as.numeric(data$density), NUM_CELLS)
data$time[is.na(data$answer)] <- TIMEOUT
data$solved <- data$time < TIMEOUT
data$min_time <- apply(data, 1, find_min_time)
data$best <- data$time == data$min_time & data$time < TIMEOUT

# Check how many entries there are in each group
#data %>% group_by(tw_bin) %>% summarise(n = n())
#data %>% group_by(density_bin) %>% summarise(n = n())

# Different ways to group the data, summarizing the proportion of solved
# instances
#df <- data %>% group_by(tw_bin, algorithm) %>%
#  summarise(prop_solved = mean(solved))
#df2 <- data %>% group_by(density_bin, algorithm) %>%
#  summarise(prop_solved = mean(solved))
#ggplot(df, aes(tw_bin, prop_solved, colour = algorithm)) +
#  geom_point() + geom_line()
#ggplot(df2, aes(density_bin, prop_solved, colour = algorithm)) +
#  geom_point() + geom_line()

df3_partial <- data %>%
  group_by(algorithm, density_bin, tw_bin) %>%
  summarise(total_best = sum(best), total_time = sum(time))
df3_partial$ranking <- df3_partial$total_best * 10 * max(df3_partial$total_time) - df3_partial$total_time
levels(df3_partial$tw_bin)[levels(df3_partial$tw_bin) == "(655,2.21e+04]"] <- "(655,22110]"

# Cells that have multiple winners
#for_testing <- df3_partial %>%
#  group_by(density_bin, tw_bin) %>%
#  filter(sum(total_best) > 0) %>%
#  summarise(n1 = algorithm[which.max(total_best)],
#            n2 = rev(algorithm)[which.max(rev(total_best))])
#for_testing[for_testing$n1 != for_testing$n2,]

df3 <- df3_partial %>%
  group_by(density_bin, tw_bin) %>%
  filter(sum(total_best) > 0) %>%
  summarise(best_algorithm = algorithm[which.max(ranking)])
#tikz(file = "../doc/v4/real.tex", width = 4.8, height = 3.9, standAlone = TRUE)
#tikz(file = "../doc/talk-aiai/real.tex", width = 4.26, height = 3.3,
#     standAlone = TRUE)
#tikz(file = "../doc/talk-conference/real.tex", width = 4.28, height = 3.26,
#     standAlone = TRUE)
tikz(file = "../doc/talks/4_internal/real.tex", width = 4.28, height = 2.934,
     standAlone = TRUE)
ggplot(df3, aes(density_bin, tw_bin, fill = best_algorithm)) +
  geom_tile_pattern(aes(pattern = best_algorithm, fill = best_algorithm,
                        pattern_angle = best_algorithm),
                    pattern_spacing = 0.025) +
  xlab("$\\mu$") +
  ylab("Primal treewidth") +
  theme_set(theme_gray(base_size = 9)) +
  theme(legend.title = element_blank(), panel.grid.major = element_blank(),
        panel.background = element_blank(),
        axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
  scale_fill_brewer(palette = "Dark2")
dev.off()
