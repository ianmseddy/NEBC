getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("SpaDES.project", "0.0.8.9040")
# getOrUpdatePkg("LandR", "1.1.1")

currentName <- "Taiga"
if (currentName == "Taiga") {
  ecoprovince <- c("4.3")
  studyAreaPSPprov <- c("4.3", "12.3", "14.1", "9.1") #this is a weird combination

} else {
  ecoprovince <- "14.1"
  studyAreaPSPprov <- c("14.1", "14.2", "14.3", "14.4")
}

if (!Sys.info()[["nodename"]] == "W-VIC-A127551") {
  googledrive::drive_auth(token = readRDS("googlemagic.rds"))
}

#TODO change the script so that ecoprovinceNum is consistently named in functinos
inSim <- SpaDES.project::setupProject(
  updateRprofile = TRUE,
  Restart = TRUE,
  useGit=  FALSE,
  name = "NEBC",
  paths = list(projectPath = "C:/Ian/Git/AssortedProjects/NEBC",
               modulePath = file.path("modules"),
               cachePath = file.path("cache"),
               scratchPath = tempdir(),
               inputPath = file.path("inputs"),
               outputPath = file.path("outputs")
  ),
  modules = c("PredictiveEcology/fireSense_dataPrepFit@lccFix",
              "PredictiveEcology/Biomass_borealDataPrep@development",
              "PredictiveEcology/Biomass_speciesData@development",
              "PredictiveEcology/fireSense_SpreadFit@lccFix",
              # "PredictiveEcology/fireSense_IgnitionFit@biomassFuel",
              "PredictiveEcology/canClimateData@development"
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1
  ),
  times = list(start = 2011, end = 2021),
  climateVariablesForFire = list(ignition = "CMDsm",
                                 spread = "CMDsm"),
  fireSense_ignitionFormula = paste0("ignitionsNoGT1 ~ (1|yearChar) + youngAge:CMDsm + nf_highFlam:CMDsm",
                                     " + nf_lowFlam:CMDsm + BlWhLar:CMDsm + Pine:CMDsm + PopBir:CMDsm"),
  functions = "ianmseddy/NEBC@main/R/studyAreaFuns.R",
  sppEquiv = makeSppEquiv(ecoprovinceNum = ecoprovince),
  #update mutuallyExlcusive Cols
  studyArea = setupSAandRTM(ecoprovinceNum = ecoprovince)$studyArea,
  rasterToMatch = setupSAandRTM(ecoprovinceNum = ecoprovince)$rasterToMatch,
  rasterToMatchLarge = setupSAandRTM(ecoprovinceNum = ecoprovince)$rasterToMatch,
  studyAreaLarge = setupSAandRTM(ecoprovinceNum = ecoprovince)$studyArea,
  studyAreaReporting = setupSAandRTM(ecoprovinceNum = ecoprovince)$studyAreaReporting,
  rasterToMatchReporting = setupSAandRTM(ecoprovinceNum = ecoprovince)$rasterToMatchReporting,
  studyAreaPSP = setupSAandRTM(ecoprovinceNum = studyAreaPSPprov)$studyArea |>
    terra::aggregate() |>
    terra::buffer(width = 10000),
  #params last because one of them depends on sppEquiv fuel class names
  params = list(
    .globals = list(.studyAreaName = currentName,
                    dataYear = 2011,
                    .plots = "png",
                    sppEquivCol = "LandR"),
    Biomass_borealDataPrep = list(
      overrideAgeInFires = FALSE,
      overrideBiomassInFires = FALSE,
      .useCache = c(".inputObjects", "init")
    ),
    canClimateData = list(
      projectedClimateYears = 2011:2061
    ),
    fireSense_SpreadFit = list(
      # mutuallyExclusiveCols = list(
      #   youngAge = c("nf", unique(makeSppEquiv(ecoprovinceNum = ecoprovince)$fuel))
      # ),
      #cacheID_DE = "previous", Not a param?
      cores = pemisc::makeIpsForNetworkCluster(
        ipStart = "10.20.0",
        ipEnd = c(189, 213, 220, 217, 106),
        availableCores = c(28, 28, 28, 14, 14),
        availableRAM = c(500, 500, 500, 250, 250),
        localHostEndIp = 189,
        proc = "cores",
        nProcess = 10,
        internalProcesses = 10,
        sizeGbEachProcess = 1),
      trace = 1,
      mode = c("fit", "visualize"),
      # mode = c("debug"),
      SNLL_FS_thresh = 2100,
      doObjFunAssertions = FALSE
    ),
    fireSense_dataPrepFit = list(
      spreadFuelClassCol = "fuel",
      ignitionFuelClassCol = "fuel"
    ),
    fireSense_IgnitionFit = list(
      rescalers = c("CMDsm" = 1000)
    )
  )
)

#add this after because of the quoted functions
inSim$climateVariables <- list(
  historical_CMDsm = list(
    vars = "historical_CMD_sm",
    fun = quote(calcAsIs),
    .dots = list(historical_years = 1991:2022)
  ),
  projected_CMDsm = list(
    vars = "future_CMD_sm",
    fun = quote(calcAsIs),
    .dots = list(future_years = 2011:2061)
  )
)

# mytoken <- gargle::gargle2.0_token(email = "ianmseddy@gmail.com")
# saveRDS(mytoken, "googlemagic.rds")
inSim$params$fireSense_SpreadFit$mutuallyExclusiveCols = list(
  youngAge = c("nf", unique(inSim$sppEquiv$fuel))
)

outSim <- do.call(what = SpaDES.core::simInitAndSpades, args = inSim)

saveSimList(outSim, paste0("outputs/outSim_", currentName, ".rds"),
            outputs = FALSE, inputs = FALSE, cache = FALSE)

#correlation between MDC and CMDsm for ever pixel over time = 0.85
#correlation of mean MDC and CMDsm in ever pixel is 0.97
#correlation between annual ignitions and CMDsm is 0.37 for CMDsm and 0.28 for MDC
#in general this is lower than other study areas (e.g., 0.48-0.52 in the Edehzie)
#correlation with mean fire size is much higher
#              MDC       CMDsm     igs          meanFireSize maxFireSize
# MDC          1.0000000 0.9063241 0.2656245    0.5844934   0.5434765
# CMDsm        0.9063241 1.0000000 0.3750653    0.6340060   0.6297804
# igs          0.2656245 0.3750653 1.0000000    0.5000696   0.5744303
# meanFireSize 0.5844934 0.6340060 0.5000696    1.0000000   0.9307312
# maxFireSize  0.5434765 0.6297804 0.5744303    0.9307312   1.0000000
