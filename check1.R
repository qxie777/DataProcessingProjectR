library(arrow)
library(dplyr)

ds <- open_dataset("synthetic_data_1.parquet")

expected_total <- 100501034
actual_total <- ds |> summarise(n = n()) |> collect() |> pull(n)

cat("Expected total cases:", expected_total, "\n")
cat("Actual total cases:  ", actual_total, "\n")
cat("Match?", actual_total == expected_total, "\n")