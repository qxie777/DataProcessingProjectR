library(arrow)
library(dplyr)

ds <- open_dataset("synthetic_data_1.parquet")

top_counties <- ds |>
  select(fips) |>
  group_by(fips) |>
  summarise(case_count = n()) |>
  arrange(desc(case_count)) |>
  head(10) |>
  collect()

print(top_counties)