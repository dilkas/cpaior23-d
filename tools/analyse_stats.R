library(ggplot2)

data <- read.csv("../stats.csv")


ggplot(data, aes(x = variables)) + geom_histogram()
ggplot(data, aes(x = equal_weights / variables)) + geom_histogram()
ggplot(data, aes(x = tw)) + geom_histogram()
ggplot(data, aes(x = clauses / variables)) + geom_histogram()
ggplot(data, aes(x = literals / clauses)) + geom_histogram()

summary(data$variables)
summary(data$equal_weights / data$variables)
summary(data$tw)
summary(data$clauses / data$variables)
summary(data$literals / data$clause)
