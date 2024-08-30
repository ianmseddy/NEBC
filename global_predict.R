#global_predict#
#for now we will pass objects to BCore. Ideally we just run it

getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("SpaDES.project", "0.0.8.9040")
# getOrUpdatePkg("LandR", "1.1.1")

currentName <- "Skeena" #toggle between Skeena and Taiga
if (currentName == "Taiga") {
  ecoprovince <- c("4.3")
  studyAreaPSPprov <- c("4.3", "12.3", "14.1", "9.1") #this is a weird combination
  snll_thresh = 2100
} else {
  ecoprovince <- "14.1"
  #this is the the outputs of the fitted simList- need better system
  inSim_Fit <- readRDS("outputs/Skeena/outSim_Skeena/outputs/outSim_Skeena.rds")
  studyAreaPSPprov <- c("14.1", "14.2", "14.3", "14.4")
  snll_thresh = 1200
}

if (!Sys.info()[["nodename"]] == "W-VIC-A127551") {
  #this must be run in advance at some point -
  # I don't know how to control the token expiry - gargle documentation is crappy
  # mytoken <- gargle::gargle2.0_token(email = "ianmseddy@gmail.com")
  # saveRDS(mytoken, "googlemagic.rds")
  googledrive::drive_auth(email = "ianmseddy@gmail.com",
                          token = readRDS("googlemagic.rds"))
}

#TODO change the script so that ecoprovinceNum is consistently named in functinos
inSim <- SpaDES.project::setupProject(
  updateRprofile = TRUE,
  Restart = TRUE,
  useGit=  TRUE,
  name = "NEBC",
  paths = list(projectPath = "C:/Ian/Git/AssortedProjects/NEBC",
               modulePath = file.path("modules"),
               cachePath = file.path("cache"),
               scratchPath = tempdir(),
               inputPath = file.path("inputs"),
               outputPath = file.path("outputs", currentName)
  ),
  modules = c("PredictiveEcology/Biomass_core@development",
              "PredictiveEcology/fireSense_dataPrepPredict@development",
              "PredictiveEcology/fireSense_SpreadPredict@development",
              "PredictiveEcology/fireSense_IgnitionPredict@development",
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
  functions = "ianmseddy/NEBC@main/R/studyAreaFuns.R",
  sppEquiv = makeSppEquiv(ecoprovinceNum = ecoprovince),
  #update mutuallyExlcusive Cols
  studyArea = inSim_Fit$studyArea,
  rasterToMatch = inSim_Fit$rasterToMatch,
  species = inSim_Fit$species,
  speciesEcoregion = inSim_Fit$speciesEcoregion,
  sufficientLight = inSim_Fit$sufficientLight,
  minRelativeB = inSim_Fit$minRelativeB,
  covMinmax_spread = inSim_Fit$covMinMax_spread,
  landcoverDT = inSim_Fit$landcoverDT2011,
  pixelGroupMap = inSim_Fit$pixelGroupMap2011,
  cohortData = inSim_Fit$cohortData2011,
  biomassMap = inSim_Fit$biomassMap,
  projectedClimateRasters = inSim_Fit$projectedClimateRasters,
  climateVariablesForFire = inSim_Fit$climateVariablesForFire,
  ecoregion = inSim_Fit$ecoregion,
  ecoregionMap = inSim_Fit$ecoregionMap,
  nonForestedLCCGroups = list(
    "nf_dryland" = c(50, 100, 40), # shrub, herbaceous, bryoid
    "nf_wetland" = c(81)), #non-treed wetland.
  #params last because one of them depends on sppEquiv fuel class names
  params = list(
    .globals = list(.studyAreaName = currentName,
                    dataYear = 2011,
                    .plots = "png",
                    sppEquivCol = "LandR")
  )
)

rm(inSim_Fit)

outSim <- do.call(what = SpaDES.core::simInitAndSpades, args = inSim)

saveSimList(outSim, paste0("outputs/outSim_", currentName, ".rds"),
            outputs = FALSE, inputs = FALSE, cache = FALSE)


