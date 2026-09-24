library(arrow)
library(dplyr)
library(ggplot2)

ds <- open_dataset("synthetic_data_1.parquet")

# Only pulls the "date" column into memory, then counts cases per day
daily_counts <- ds |>
  select(date) |>
  group_by(date) |>
  summarise(case_count = n()) |>
  collect() |>
  arrange(date)

# Make sure date is treated as an actual date
daily_counts$date <- as.Date(daily_counts$date)

ggplot(daily_counts, aes(x = date, y = case_count)) +
  geom_line() +
  labs(title = "Synthetic Daily Covid-19 Cases", x = "Date", y = "Number of cases") +
  theme_minimal()

ggsave("daily_cases_plot.png", width = 10, height = 5)
cat("Saved chart as daily_cases_plot.png\n")