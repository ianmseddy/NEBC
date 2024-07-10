
makeLCCFact <- function(rstLCC) {
  lccCats <- data.table(val = c(20, 31, 32, 33, 40, 50, 80, 81, 100, 210, 220, 230, 240),
                        class = c("water", "snow_ice", "rock rubble", "barren", "bryoids",
                                  "shrubs", "nontreed wetland", "treed wetland", "herbs",
                                  "coniferous", "broadleaf", "mixedwood", "dist. forest"))

  #shamelessly ripped off stack exchange
  goodColors25 <- c(
    "dodgerblue2", "#E31A1C", # red
    "green4",
    "#6A3D9A", # purple
    "#FF7F00", # orange
    "black",
    "gold1",
    "skyblue2",
    "#FB9A99", # lt pink
    "palegreen2",
    "#CAB2D6", # lt purple
    "#FDBF6F", # lt orange
    "gray70",
    "khaki2",
    "maroon",
    "orchid1",
    "deeppink1",
    "blue1",
    "steelblue4",
    "darkturquoise",
    "green1",
    "yellow4",
    "yellow3",
    "darkorange4",
    "brown"
  )

  setkey(lccCats, val)
  lccCats[, newCol := c("blue1", "lightblue", "gray70", "#CAB2D6", "yellow2",
                        "yellow4", "darkturquoise", "aquamarine", "palegreen2", "green4",
                        "green", "green3", "black")]

  levels(rstLCC) <- lccCats
  return(rstLCC)
}
