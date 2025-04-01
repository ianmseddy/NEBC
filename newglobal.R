repos <- c("predictiveecology.r-universe.dev", getOption("repos"))
# Need the latest version
if (tryCatch(packageVersion("SpaDES.project") < "0.1.1", error = function(x) TRUE)) {
  install.packages(c("SpaDES.project", "Require"), repos = repos)
}

FRU <- 60

inSim <- SpaDES.project::setupProject(
  require = "PredictiveEcology/scfmutils@development",
  packages = c("usethis", "googledrive", "httr2"),
  useGit=  TRUE,
  paths = list(projectPath = "NEBC",
               modulePath = file.path("modules"),
               cachePath = file.path("cache"),
               scratchPath = tempdir(),
               inputPath = file.path("inputs"),
               outputPath = file.path("outputs", paste0("FRU", FRU))
  ),
  modules = c("PredictiveEcology/fireSense_dataPrepFit@WIP-flammableMap",
              "PredictiveEcology/canClimateData@development"
              # "PredictiveEcology/Biomass_borealDataPrep@development"
              # "PredictiveEcology/Biomass_core@development",
              # "PredictiveEcology/fireSense@development",
              # "PredictiveEcology/Biomass_speciesData@development",
              #,
              # "PredictiveEcology/fireSense_SpreadFit@lccFix",
              # "PredictiveEcology/fireSense_IgnitionFit@development",
              # "PredictiveEcology/fireSense_EscapeFit@development"
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 useCache = TRUE,
                 gargle_oauth_email = "ianmseddy@gmail.com",
                 gargle_oauth_cache = "~/google_drive_cache",
                 gargle_oauth_client_type = "web", #I think?
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1
  ),
  times = list(start = 2011, end = 2011),
  climateVariablesForFire = list(ignition = c("CMDsm", "CMDsp"),
                                 spread = c("CMDsm", "CMDsp")),
  functions = "ianmseddy/NEBC@main/R/studyAreaFuns.R",
  #update mutuallyExlcusive Cols
  studyArea = {
    sa <- scfmutils::prepInputsFireRegimePolys(destinationPath = "inputs",
                                               type = "FRU")
    sa <- sa[sa$PolyID == FRU,]
    sa <- terra::vect(sa)
    sa <- terra::buffer(sa, 5000)
  },
  rasterToMatch = {
    rtm <- terra::rast(sa, res = c(250, 250))
    rtm[] <- sample(1:3, terra::ncell(rtm), replace = TRUE)
    rtm <- reproducible::postProcess(rtm, maskTo = sa)
  },
  rasterToMatchLarge = rasterToMatch,
  studyAreaLarge = studyArea,
  sppEquiv = {
    spp <- LandR::speciesInStudyArea(studyArea = studyArea,
                                     dPath = "inputs",)
    sppEquiv <- LandR::sppEquivalencies_CA[KNN %in% spp$speciesList,]
    sppEquiv <- sppEquiv[grep(pattern = "Spp", x = sppEquiv$KNN, invert = TRUE),]
  },
  params = list(
    .globals = list(.studyAreaName = paste0("FRU", FRU),
                    dataYear = 2011,
                    .plots = "png",
                    sppEquivCol = "LandR"),
    Biomass_borealDataPrep = list(
      overrideAgeInFires = FALSE,
      overrideBiomassInFires = FALSE,
      .useCache = c(".inputObjects", "init")
    ),
    canClimateData = list(".useCache" = c(".inputObjects", "init")),
    fireSense_IgnitionFit = list(
      rescalers = c("CMDsm" = 1000,
                    "CMDsp" = 1000)
    )
  )
)


inSim$climateVariables <- list(
  historical_CMDsm = list(
    vars = "historical_CMD_sm",
    fun = quote(calcAsIs),
    .dots = list(historical_years = 1991:2022)
  ),
  historical_CMDsp = list(
    vars = "historical_CMD_sp",
    fun = quote(calcAsIs),
    .dots = list(historical_years = 1991:2022)
  )
)

#known bugs/undesirable behavior
#1 spreadFit dumps a bunch of figs in the project directory instead of outputs
#2 canClimateData occasionally fails, rather mysteriously. Unclear if
#3 Google Auth can be irritating when running via Bash


outSim <- SpaDES.core::simInitAndSpades2(inSim)

