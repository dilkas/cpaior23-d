library(plyr)
library(dplyr)
library(ggplot2)
library(maditr)
library(Hmisc)
library(tikzDevice)
library(ggpubr)

# For testing
data <- read.csv("../results/satisfiability.csv")
data <- data[data$literal_factor > 1,]
bounds <- t(apply(data, 1, function(x)
  c(100, as.integer(100 * as.numeric(x[7])), as.integer(x[6]),
             as.numeric(x[1]))))
data <- cbind(data, bounds = bounds)
print(data)

repetitiveness_facets <- function(filename, round_clause_factor_labels) {
  data <- read.csv(filename)
  data <- data[data$literal_factor > 1,]

  bounds <- t(apply(data, 1, function(x)
    c(100, as.integer(100 * as.numeric(x[7])), as.integer(x[6]),
               as.numeric(x[1]))))
  data <- cbind(data, bounds = bounds)

  if (round_clause_factor_labels) {
    levels <- sort(unique(data$clause_factor))
    data$clause_factor <- factor(data$clause_factor, levels = levels,
                                 labels = round(levels, 1))
  }
  ggplot(data, aes(repetitiveness, treewidth)) +
    geom_point() +
    geom_smooth(se = FALSE, method = "loess") +
    facet_grid(literal_factor ~ clause_factor, labeller =
                 labeller(literal_factor = function(x) paste0("$\\kappa = ",
                                                              x, "$"),
                          clause_factor = function(x) paste0("$\\mu = ",
                                                             x, "$"))) +
    scale_x_continuous(breaks = c(0, 0.5, 1), labels = c(0, 0.5, 1)) +
    scale_y_continuous(breaks = c(0, 50, 100)) +
    xlab("$\\rho$") +
    ylab("Primal treewidth") +
#    geom_ribbon(aes(ymin = bounds.1, ymax = bounds.2), fill = "red") +
#    geom_ribbon(aes(ymin = bounds.3, ymax = bounds.4), fill = "green") +
    theme_set(theme_gray(base_size = 9))
}
tikz(file = "../doc/kr/regular_repetitiveness.tex", width = 6.5,
     height = 4.516875, standAlone = TRUE)
repetitiveness_facets("../results/satisfiability.csv", TRUE)
dev.off()

# ========== EXTRA STUFF ===========

satisfiability_heatmap <- function(filename) {
  data <- read.csv(filename)
  df2 <- data %>% group_by(clause_factor, literal_factor) %>%
    summarise(satisfiability = (sum(sat) / n()))
  df2$clause_factor <- as.factor(df2$clause_factor)
  df2$literal_factor <- as.factor(df2$literal_factor)
  ggplot(df2, aes(clause_factor, literal_factor)) +
    geom_tile(aes(fill = satisfiability)) +
    geom_text(aes(label = round(satisfiability, 1))) +
    xlab("$\\mu$") +
    ylab("$\\kappa$") +
    labs(fill = "Satisfiability") +
    scale_fill_distiller(palette = "Blues") +
    scale_x_discrete(labels = function(x) sprintf("%.1f", as.numeric(x)))
}
p1 <- satisfiability_heatmap(
  "../experiments/satisfiability/irregular_results.csv")
p2 <- satisfiability_heatmap(
  "../experiments/satisfiability/regular_results.csv")
tikz(file = "../paper/satisfiability.tex", width = 6.5, height = 2.4375)
ggarrange(p1, p2, ncol = 2, common.legend = TRUE, legend = "bottom")
dev.off()

data <- read.csv("../experiments/satisfiability/regular_results.csv")
df <- data[data$literal_factor == 3,] %>%
  group_by(repetitiveness) %>%
  summarise(mean = mean(sat))
