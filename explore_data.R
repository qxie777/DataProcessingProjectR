library(arrow)

# Open a connection to the file without loading any actual data
pq <- ParquetFileReader$create("synthetic_data_1.parquet")
schema <- pq$GetSchema()

cat("Number of rows:", pq$ReadTable()$num_rows, "\n")
cat("Column names:", paste(schema$names, collapse = ", "), "\n")