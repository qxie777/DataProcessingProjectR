library(arrow)
library(dplyr)

ds <- open_dataset("synthetic_data_1.parquet")

coord_ranges <- ds |>
  select(latitude, longitude) |>
  summarise(
    lat_min = min(latitude), lat_max = max(latitude),
    lon_min = min(longitude), lon_max = max(longitude)
  ) |>
  collect()

print(coord_ranges)