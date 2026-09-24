url <- "https://zenodo.org/records/21442375/files/synthetic_data_1.parquet?download=1"
output_file <- "synthetic_data_1.parquet"

cat("Downloading... this may take a few minutes (file is ~1.8 GB)\n")

download.file(url, destfile = output_file, mode = "wb")

cat("Done! Saved as", output_file, "\n")