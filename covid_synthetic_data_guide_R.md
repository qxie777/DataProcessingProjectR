# Downloading and Checking a Synthetic Covid-19 Dataset (R Guide)

This guide walks you through downloading **one** synthetic Covid-19 dataset (out of 28 available) from the researchers' public repository, and running some basic checks to see if it "makes sense" — all in R.

**What you'll need:**
- R installed (RStudio is recommended, but any R setup works)
- About 2 GB of free disk space
- A decent internet connection (the file is ~1.8 GB)
- Basic comfort running R scripts and installing packages

**A note on memory:** this guide assumes a computer with **16 GB of RAM**. Every check below only loads the 1–2 columns it actually needs (instead of the whole 100+ million row file), so each one should comfortably use well under 1–2 GB of RAM.

---

## Step 1: Install the packages you'll need

Open RStudio (or your R console) and run:

```r
install.packages(c("arrow", "dplyr", "ggplot2"))
```

**What these do:**
- `arrow` — lets R read `.parquet` files (the format this dataset comes in), and lets us peek at file metadata or specific columns *without* loading the whole file
- `dplyr` — makes it easy to filter, group, and summarize tables of data
- `ggplot2` — lets us make a simple chart to visually check the data

---

## Step 2: Download one synthetic dataset file

Create a new R script called `download_data.R`:

```r
url <- "https://zenodo.org/records/21442375/files/synthetic_data_1.parquet?download=1"
output_file <- "synthetic_data_1.parquet"

cat("Downloading... this may take a few minutes (file is ~1.8 GB)\n")

download.file(url, destfile = output_file, mode = "wb")

cat("Done! Saved as", output_file, "\n")
```

Run it (either by clicking "Source" in RStudio, or from a terminal with `Rscript download_data.R`).

> 💡 **If the download seems to hang or fail:** some R setups time out on large files by default. Add this line before `download.file()` to raise the timeout to 30 minutes:
> ```r
> options(timeout = 1800)
> ```

---

## Step 3: Peek at the data without loading the whole thing

With 100.5 million rows, loading **every column** into memory at once can use way more than 16 GB of RAM. So instead, we'll first look at just the file's *metadata* (row count, column names) — this uses almost no memory at all.

Create a new file called `explore_data.R`:

```r
library(arrow)

# Open a connection to the file without loading any actual data
pq <- ParquetFileReader$create("synthetic_data_1.parquet")
schema <- pq$GetSchema()

cat("Number of rows:", pq$ReadTable()$num_rows, "\n")
cat("Column names:", paste(schema$names, collapse = ", "), "\n")
```

> 💡 **Note:** unlike some formats, getting the exact row count from a parquet file's metadata in R's `arrow` package requires briefly touching the file structure (not the actual column data), so this step is still very fast and light on memory compared to loading real values.

Run it. You should see **100,501,034 rows** and columns for longitude, latitude, FIPS code, GEO_ID, and date. This confirms the file downloaded correctly.

> 💡 **The rule for the rest of this guide:** every check below uses `arrow`'s `open_dataset()` function combined with `dplyr`, which only reads the specific column(s) it needs — even though the file has 100+ million rows.

---

## Step 4: Check #1 — Does the total number of cases match?

The paper claims each synthetic file should have **exactly 100,501,034 rows** (one row per real Covid-19 case).

```r
library(arrow)
library(dplyr)

ds <- open_dataset("synthetic_data_1.parquet")

expected_total <- 100501034
actual_total <- ds |> summarise(n = n()) |> collect() |> pull(n)

cat("Expected total cases:", expected_total, "\n")
cat("Actual total cases:  ", actual_total, "\n")
cat("Match?", actual_total == expected_total, "\n")
```

`open_dataset()` doesn't load the file into memory — it creates a "lazy" connection. The `n()` count is computed efficiently without pulling every row's actual values into R.

---

## Step 5: Check #2 — Do daily case counts look realistic over time?

Let's group all the cases by date and plot them, to see if it looks like a real pandemic curve (with waves of cases rising and falling).

```r
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
```

Open `daily_cases_plot.png` afterward. You should see recognizable Covid-19 "waves" (like the big Omicron spike in early 2022). If the line looks like random noise instead of realistic waves, something would be wrong.

---

## Step 6: Check #3 — Do the top counties make sense?

Densely populated counties (like Los Angeles County or Cook County, Illinois) should have the most cases, since the whole method is based on population weighting.

```r
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
```

Look up a couple of these FIPS codes online (e.g., search "FIPS code 06037") — you should find that the top codes correspond to large, populous counties like Los Angeles County, CA.

---

## Step 7: Check #4 (bonus) — Spot-check that points fall inside the U.S.

A simple sanity check: latitude and longitude values should be within the roughly boundaries of the United States (including Alaska, Hawaii, and Puerto Rico).

```r
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
```

Roughly, you'd expect:
- Latitude: somewhere between about 17°N (Puerto Rico) and 72°N (northern Alaska)
- Longitude: somewhere between about -180° and -65° (spanning from Alaska to the East Coast)

If you see values wildly outside this range (like latitude 500, or longitude -1), that would signal a problem with the data.

---

## What you've done

By the end of this guide, you will have:
1. ✅ Downloaded a real ~1.8 GB scientific dataset
2. ✅ Verified the total row count matches what the researchers claimed
3. ✅ Visually checked that the disease timeline looks realistic
4. ✅ Confirmed that the most-affected counties make demographic sense
5. ✅ Checked that all coordinates fall within realistic U.S. bounds

This is the same basic idea researchers use in "technical validation" — you're not just trusting a paper's claims, you're checking them yourself with data!

### A note on memory (for a 16 GB machine)
`open_dataset()` combined with `select()` and `summarise()` lets `arrow` push most of the work down to the file itself, only bringing the final small summary table into R's memory. This keeps every check in this guide well under 1–2 GB of RAM, even though the full file has 100+ million rows. The one thing to avoid is calling something like `read_parquet("synthetic_data_1.parquet")` (loading the *entire* file as a regular data frame with no filtering) — that can use 15–20+ GB and may slow down or crash a 16 GB machine.

### Where to go next
If you want to dig deeper, you could compare this synthetic file against the real reference data (`Covid_19_County_Case_Data.rda`) also available in the same repository, to reproduce the paper's exact correlation numbers (Pearson/Spearman) — that's a great next step once you're comfortable with the basics above.
