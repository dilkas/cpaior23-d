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

repetitiveness_facets <- function(filename, round_clause_factor_labels,
                                  kappa_name = "\\kappa", with_mu = TRUE,
                                  xbreaks = c(0, 0.5, 1),
                                  ybreaks = c(0, 50, 100)) {
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
  p <- ggplot(data, aes(repetitiveness, treewidth)) +
    geom_point() +
    geom_smooth(se = FALSE, method = "loess") +

    scale_x_continuous(breaks = xbreaks, labels = xbreaks) +
    scale_y_continuous(breaks = ybreaks) +
    xlab("$\\rho$") +
    ylab("Primal treewidth") +
    theme_set(theme_gray(base_size = 9))
  if (with_mu) {
    p + facet_grid(literal_factor ~ clause_factor,
                   labeller = labeller(
                     literal_factor = function(x) paste0("$", kappa_name, " = ", x, "$"),
                     clause_factor = function(x) paste0("$\\mu = ", x, "$")))
  } else {
    p + facet_grid(literal_factor ~ clause_factor, labeller = labeller(
      literal_factor = function(x) paste0("$", kappa_name, " = ", x, "$"),
      clause_factor = function(x) x))
  }
}

# tikz(file = "../doc/kr/regular_repetitiveness.tex", width = 6.5,
#      height = 4.516875, standAlone = TRUE)
#tikz(file = "../doc/workshop/regular_repetitiveness.tex", width = 4.8,
#     height = 4.516875, standAlone = TRUE)

#tikz(file = "../../annual-report/thesis/chapters/comparison/regular_repetitiveness.tex",
#     width = 5.7, height = 3.1, standAlone = TRUE)
#repetitiveness_facets("../results/satisfiability.csv", TRUE)

#tikz(file = "../doc/talk/regular_repetitiveness.tex", width = 4.26,
#     height = 3.3, standAlone = TRUE)
#repetitiveness_facets("../results/satisfiability.csv", TRUE, "k", FALSE,
#                      c(0, 1), c(0, 100))
#dev.off()

tikz(file = "../doc/talk-conference/regular_repetitiveness.tex", width = 4.28,
     height = 3.26, standAlone = TRUE)
repetitiveness_facets("../results/satisfiability.csv", TRUE, "k", FALSE,
                      c(0, 1), c(0, 100))
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
