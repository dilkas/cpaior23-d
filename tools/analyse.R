library(plyr)
library(dplyr)
library(ggplot2)
library(maditr)
library(Hmisc)
library(tikzDevice)
library(ggpubr)
library(ggthemes)

source("util.R")

data <- read_data("../results/regular1.csv")
fits <- expand.grid(sort(unique(data$algorithm)), unique(data$clause_factor))
names(fits) <- c("algorithm", "clause_factor")
results <- mapply(fit_model, fits$algorithm, fits$clause_factor)
fits$fit <- exp(results[1,])
fits$lb <- exp(results[1,] - results[2,])
fits$ub <- exp(results[1,] + results[2,])

# First round: density & treewidth (treewidth.tex/pdf, from util.R)
# NB: Calling the function doesn't work for some reason. It must be executed
# 'by hand'.
plot_4_plots(data, fits)

# R^2
r2table <- cbind(fits, r2 = results[3,])
r2table$r2[r2table$algorithm == "\\textsc{d4}" &
             r2table$clause_factor == 4.3] <- 1
r2table$clause_factor <- as.factor(r2table$clause_factor)

#tikz(file = "../doc/kr/r2.tex", width = 3, height = 3, standAlone = TRUE)
#tikz(file = "../../annual-report/thesis/chapters/comparison/r2.tex",
#     width = 3.1, height = 3.1, standAlone = TRUE)
tikz(file = "../doc/talk/r2.tex", width = 4.26, height = 2.9, standAlone = TRUE)
ggplot(r2table, aes(algorithm, clause_factor, fill = r2)) + geom_tile() +
  geom_text(aes(label = round(r2, 2))) +
  xlab(NULL) +
  ylab("$\\mu$") +
  scale_fill_distiller(palette = "Purples",
                       guide = guide_colorbar(direction = "horizontal")) +
  labs(fill = "$R^2$") +
  theme_set(theme_gray(base_size = 9)) +
  theme(legend.position = "bottom",
        legend.margin = margin(t = 0, unit = 'cm'))
dev.off()

# Second round: delta & epsilon
data <- read_data("../results/regular2.csv")
df <- data %>% group_by(algorithm, prop_deterministic)
p1 <- plot_with_sd(df, "prop_deterministic", "$\\delta$") + ylim(0, TIMEOUT)
data <- read_data("../results/regular3.csv")
df <- data %>% group_by(algorithm, prop_equal)
p2 <- plot_with_sd(df, "prop_equal", "$\\epsilon$") + ylim(0, TIMEOUT)
#figure <- ggarrange(p1, p2, common.legend = TRUE, legend = "right")
figure <- ggarrange(p1 + rremove("ylab"), p2 + rremove("ylab"),
                    common.legend = TRUE, legend = "bottom")

# tikz(file = "../doc/kr/delta_epsilon.tex", width = 6.5, height = 1.505625,
#      standAlone = TRUE)
#tikz(file = "../doc/workshop/delta_epsilon.tex", width = 4.8,
#     height = 1.505625, standAlone = TRUE)
tikz(file = "../../annual-report/thesis/chapters/comparison/delta_epsilon.tex",
     width = 5.7, height = 3.1, standAlone = TRUE)
annotate_figure(figure, left = text_grob("Time (s)", rot = 90, vjust = 1,
                                         size = 9))
dev.off()

# for slides
data <- read_data("../results/regular3.csv")
df <- data[data$algorithm == "\\textsc{DPMC}", ] %>% group_by(prop_equal)
tikz(file = "../doc/talk/epsilon.tex", width = 4.26, height = 3.1,
     standAlone = TRUE)
plot_with_sd(df, "prop_equal", "$\\epsilon$", FALSE) +
  ylim(0, TIMEOUT) +
  theme_light() + ylab("\\textsc{DPMC} runtime (s)")
dev.off()

# ==================== EXTRA STUFF ====================

# Scalability data
data1 <- read.csv("../experiments/scalability/irregular.csv")
data1$type <- "non-$k$-CNF"
data2 <- read.csv("../experiments/scalability/regular.csv")
data2$type <- "$k$-CNF"
data <- rbind(data1, data2)
data$algorithm[data$algorithm == "c2d"] <- "\\textsc{c2d}"
data$algorithm[data$algorithm == "cachet"] <- "\\textsc{Cachet}"
data$algorithm[data$algorithm == "d4"] <- "\\textsc{d4}"
data$algorithm[data$algorithm == "dpmc"] <- "\\textsc{DPMC}"
data$algorithm[data$algorithm == "minic2d"] <- "\\textsc{miniC2D}"
tikz(file = "../paper/scalability.tex", width = 6.5, height = 2.4375)
ggplot(data, aes(num_variables, time, color = algorithm,
                 linetype = algorithm)) +
  geom_smooth() +
  xlab("$\\nu$") +
  ylab("Time (s)") +
  labs(color = "Algorithm", linetype = "Algorithm") +
  facet_wrap(~ type, scales = "free") +
  scale_color_brewer(palette = "Dark2")
dev.off()

# Check answers
answers <- data %>% dcast(instance ~ algorithm, value.var = "answer")
proportion <- function(algorithm1, algorithm2) {
  differences <- !is.na(answers[[algorithm1]]) & !is.na(answers[[algorithm2]])
  & abs(answers[[algorithm1]] - answers[[algorithm2]]) <=
    pmax(0.01, 0.01 * pmin(answers[[algorithm1]], answers[[algorithm2]]))
  differences2 <- !is.na(answers[[algorithm1]]) & !is.na(answers[[algorithm2]])
  return(c(sum(differences), sum(differences2)))
}
correctness <- expand.grid(algorithm1 = sort(unique(data$algorithm)),
                           algorithm2 = sort(unique(data$algorithm)))
correctness$algorithm1 <- as.character(correctness$algorithm1)
correctness$algorithm2 <- as.character(correctness$algorithm2)
correctness <- mdply(correctness, proportion)
correctness$V1 <- correctness$V1 / correctness$V2
ggplot(correctness, aes(algorithm1, algorithm2)) +
  geom_tile(aes(fill = V1)) +
  geom_text(aes(label = round(V1, 1)))

# Correlations
correlation_data <- data[, c("repetitiveness", "prop_deterministic",
                             "literal_factor", "clause_factor", "treewidth",
                             "prop_equal", "time")]
cor(correlation_data)
rcorr(as.matrix(correlation_data))

# Count missing instances
counts <- data %>% count(algorithm, clause_factor, repetitiveness)
counts <- data %>% count(algorithm, prop_deterministic, prop_equal)
