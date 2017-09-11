# analyzer.R to be used for visualizing the Hacker News frontpage
# Copyright 2017 Dominik Pataky <dom@netdecorator.org>
# Licensed under the GPLv3 license, see LICENSE

library(jsonlite)
library(ggplot2)
library(scales)
library(ggrepel)


# Extra labeling, too much for normal plot
flag.repel = F

# Create png target directory if it does not exist
if (!dir.exists('./pngs')) {
  dir.create('./pngs')
}

processed = 1
to_process = length(list.files('./snaps/', full.names=F))

# Iterate over all snapshot JSON files in directory
for(filename in list.files('./snaps/', full.names=TRUE)) {
  print(sprintf("Processing %i/%i", processed, to_process))

  # Parse the JSON file as JSON
  result_json <- read_json(path=filename,
    simplifyVector=T, simplifyDataFrame=T, flatten=T)

  # Extract the headlines data frame
  headlines = result_json$headlines

  if (length(headlines) == 0) {
    # Skip empty results
    print(sprintf("Skipping %s because it has no data", filename))
    processed = processed + 1
    next
  }

  # Create target filename
  filename.target = paste(result_json$timestamp, '.png', sep = '')

  # Check if file exists and skip if true
  if (file.exists(file.path('./pngs', filename.target))) {
    print(sprintf("Skipping PNG creation since %s exists already", filename.target))
    processed = processed + 1
    next
  }

  # Convert timestamp from Unix to CET
  timestamp_cet = as.POSIXct(result_json$timestamp, origin="1970-01-01")

  # Join png subfolder with filename sans '.json' extension
  png(file.path('./pngs', filename.target), height = 720, width = 1280)

  # Create the plot
  plotted <- ggplot(headlines, aes(score, commentcount)) +
    ggtitle(timestamp_cet) +
    theme_bw(base_size = 10) + xlab("Points") + ylab("Comments") +
    scale_x_continuous(trans = log2_trans(),
                       breaks = seq(0, 1000, 50),
                       limits = c(40,NA)) +
    scale_y_continuous(trans = log2_trans(),
                       breaks = seq(0, 1000, 20),
                       limits = c(20,NA)) +
    scale_fill_gradient(low = "green", high = "red") +
    geom_label(aes(label=sprintf("(%i) %s", rank, title), fill=-rank),
               show.legend = F, size=3.5, label.r = unit(0.2, "lines"),
               label.size = 0.2, label.padding = unit(0.25, "lines"))

  # Extra labeling
  if (flag.repel) {
    plotted <- plotted + geom_label_repel(
      aes(label=sprintf("(%i) %s", rank, title), fill=-rank),
      box.padding = unit(0.65, "lines"),
      point.padding = unit(0.4, "lines"),
      segment.color = 'grey60', size=3)
  }

  # Pipe the plot into a file
  print(plotted)

  # Close png device, write to disk
  dev.off()

  processed = processed + 1
}
