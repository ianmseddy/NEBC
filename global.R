getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("Require", "0.3.1.9015")
getOrUpdatePkg("SpaDES.project", "0.0.8.9040")
# getOrUpdatePkg("LandR", "1.1.1")

currentName <- "Taiga"
if (currentName == "Taiga") {
  ecoProvince <- c("4.3")
  studyAreaPSPprov <- c("4.3", "12.3", "14.1", "9.1") #this is a weird combination

} else {
  ecoProvince <- "14.1"
  studyAreaPSPprov <- c("14.1", "14.2", "14.3", "14.4")
}

googledrive::drive_auth(token = readRDS("projectToken.rds"))
print("authentication line ran")
inSim <- SpaDES.project::setupProject(
  updateRprofile = TRUE,
  Restart = TRUE,
  name = "NEBC",
  paths = list(projectPath = "C:/Ian/Git/AssortedProjects/NEBC",
               modulePath = file.path("modules"),
               cachePath = file.path("cache"),
               scratchPath = tempdir(),
               inputPath = file.path("inputs"),
               outputPath = file.path("outputs")
  ),
  modules = c("PredictiveEcology/fireSense_dataPrepFit@lccFix",
                "PredictiveEcology/Biomass_borealDataPrep@development", #for lcc mapped to dataYear
                "PredictiveEcology/Biomass_speciesData@development",
                "PredictiveEcology/fireSense_SpreadFit@lccFix",
                "PredictiveEcology/canClimateData@development"
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1
  ),
  times = list(start = 2011, end = 2021),
  params = list(
    .globals = list(.studyAreaName = currentName,
                    dataYear = 2011,
                    sppEquivCol = "LandR"),
    # gmcsDataPrep = list(PSPdataTypes = c("BC", "AB", "NFI"),
    #                     doPlotting = TRUE
    #                     ),
    Biomass_borealDataPrep = list(
      overrideAgeInFires = FALSE,
      overrideBiomassinFires = FALSE
    ),
    fireSense_SpreadFit = list(
      cores = pemisc::makeIpsForNetworkCluster(
        ipStart = "10.20.0",
        ipEnd = c(97, 189, 220, 184, 106),
        availableCores = c(28, 28, 28, 14, 14),
        availableRAM = c(500, 500, 500, 250, 250),
        localHostEndIp = 97,
        proc = "cores",
        nProcess = 10,
        internalProcesses = 10,
        sizeGbEachProcess = 1),
      trace = 1, #cacheID_DE = "previous", Not a param?
      mode = c("fit", "visualize"),
      SNLL_FS_thresh = 2050,
      doObjFunAssertions = FALSE),
    fireSense_dataPrepFit = list(
      spreadFuelClassCol = "fuel",
      spreadFuelClassCol = "fuel"
    )
  ),
  climateVariablesForFire = list(ignition = "CMDsm",
                                 spread = "CMDsm"),
  functions = "ianmseddy/NEBC@main/R/studyAreaFuns.R",
  sppEquiv = makeSppEquiv(ecoProvinceNum = ecoProvince),
  studyArea = setupSAandRTM(ecoprovinceNum = ecoProvince)$studyArea,
  rasterToMatch = setupSAandRTM(ecoprovinceNum = ecoProvince)$rasterToMatch,
  rasterToMatchLarge = setupSAandRTM(ecoprovinceNum = ecoProvince)$rasterToMatch,
  studyAreaLarge = setupSAandRTM(ecoprovinceNum = ecoProvince)$studyArea,
  studyAreaPSP = setupSAandRTM(ecoprovinceNum = studyAreaPSPprov)$studyArea |>
    terra::aggregate() |>
    terra::buffer(width = 10000),
  packages = "googledrive",
  # require = c("PredictiveEcology/reproducible@modsForLargeArchives (HEAD)"),
  useGit = TRUE
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
    .dots = list(future_years = 2011:2100)
  )
)


outSim <- do.call(SpaDES.core::simInitAndSpades, inSim)

saveSimList(outSim, paste0("outputs/outSim_", currentName, ".rds"),
            outputs = FALSE, inputs = FALSE, cache = FALSE)
