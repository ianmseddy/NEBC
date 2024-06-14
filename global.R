getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("Require", "0.3.1.9015")
getOrUpdatePkg("SpaDES.project", "0.0.8.9040")

out <- SpaDES.project::setupProject(
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
                # "PredictiveEcology/fireSense_SpreadFit@lccFix",
                "PredictiveEcology/fireSense_IgnitionFit@biomassFuel",
                "PredictiveEcology/canClimateData@development"
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1
  ),
  times = list(start = 2011, end = 2021),
  params = list(
    .globals = list(.studyAreaName = "NEBC",
                    dataYear = 2011,
                    sppEquivCol = "LandR"),
    gmcsDataPrep = list(PSPdataTypes = c("BC", "AB", "NFI"),
                        doPlotting = TRUE
                        ),
    fireSense_SpreadFit = list(
      # cores = rep("localhost", 30)
      mode = "debug"
    ),
    fireSense_dataPrepFit = list(
      spreadFuelClass = "madeupFuel",
      ignitionFuelClass = "madeupFuel"
    )
  ),
  functions = "ianmseddy/NEBC@main/R/studyAreaFuns.R",
  sppEquiv = makeSppEquiv(),
  studyArea = setupSAandRTM()$studyArea,
  rasterToMatch = setupSAandRTM()$rasterToMatch,
  studyAreaLarge = setupSAandRTM()$studyArea,
  rasterToMatchLarge = setupSAandRTM()$rasterToMatch,
  studyAreaPSP = setupSAandRTM(ecoprovinceNum = c("14.1", "14.2", "14.3", "14.4"))$studyArea |>
    terra::aggregate() |>
    terra::buffer(width = 10000),
  packages = "googledrive",
  useGit = TRUE
)

out$params$gmcsDataPrep$growthModel <- quote(nlme::lme(growth ~ logAge*(ATA + CMI),
                                                       random = ~1 | OrigPlotID1,
                                                       weights = varFunc(~plotSize^0.5 * periodLength),
                                                       data = PSPmodelData))
out$params$gmcsDataPrep$nullGrowthModel <- quote(nlme::lme(growth ~ logAge,
                                                           random = ~1 | OrigPlotID1,
                                                           weights = varFunc(~plotSize^0.5 * periodLength),
                                                           data = PSPmodelData))

outSim <- do.call(SpaDES.core::simInitAndSpades, out)
