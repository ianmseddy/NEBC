
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

#TODO change the script so that ecoprovinceNum is consistently named in functions
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
  modules = c(
    #biomass inputs
    "PredictiveEcology/Biomass_core@development",
    "PredictiveEcology/Biomass_borealDataPrep@development",
    "PredictiveEcology/Biomass_speciesData@development",
    #climate inputs
    "PredictiveEcology/canClimateData@development",
    # fireSense prediction
    "PredictiveEcology/fireSense_dataPrepPredict@pendingNewClimate",
    "PredictiveEcology/fireSense_SpreadPredict@development",
    "PredictiveEcology/fireSense_IgnitionPredict@development",
    "PredictiveEcology/fireSense@development"
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1,
                 parallelly.availableCores.custom = function(){return(6)} #For Windows users
  ),
  times = list(start = 2011, end = 2051),
  climateVariablesForFire = list(ignition = "CMDsm",
                                 spread = "CMDsm"),
  functions = "ianmseddy/NEBC@main/R/studyAreaFuns.R",
  sppEquiv = makeSppEquiv(ecoprovinceNum = ecoprovince),
  studyArea = setupSAandRTM(ecoprovinceNum = ecoprovince)$studyArea,
  rasterToMatch = setupSAandRTM(ecoprovinceNum = ecoprovince)$rasterToMatch,
  rasterToMatchLarge = setupSAandRTM(ecoprovinceNum = ecoprovince)$rasterToMatch,
  studyAreaLarge = setupSAandRTM(ecoprovinceNum = ecoprovince)$studyArea,
  studyAreaReporting = setupSAandRTM(ecoprovinceNum = ecoprovince)$studyAreaReporting,
  rasterToMatchReporting = setupSAandRTM(ecoprovinceNum = ecoprovince)$rasterToMatchReporting,
  climateVariablesForFire = list(ignition = "CMDsm",
                                 spread = "CMDsm"),
  nonForestedLCCGroups = list(
    "nf_dryland" = c(50, 100, 40), # shrub, herbaceous, bryoid
    "nf_wetland" = c(81)), #non-treed wetland.
  fireSense_IgnitionFitted = readRDS("outputs/Skeena/fireSense_IgnitionFitted.rds"),
  fireSense_SpreadFitted = readRDS("outputs/Skeena/fireSense_SpreadFitted.rds"),

  #params last because one of them depends on sppEquiv fuel class names
  params = list(
    .globals = list(.studyAreaName = currentName,
                    dataYear = 2011,
                    .plots = "png",
                    sppEquivCol = "LandR"),
    canClimateData = list(
      projectedClimateYears = 2011:2061
    )
  )
)

inSim$climateVariables <- list(
  projected_CMIsm = list(
    vars = "future_CMD_sm",
    fun = quote(calcAsIs),
    .dots = list(future_years = inSim$params$canClimateData$projectedClimateYears)
  )
)

outSim <- do.call(what = SpaDES.core::simInitAndSpades, args = inSim)

# saveSimList(outSim, paste0("outputs/outSim_", currentName, ".rds"),
#             outputs = FALSE, inputs = FALSE, cache = FALSE)


