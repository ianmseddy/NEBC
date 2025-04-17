repos <- c("predictiveecology.r-universe.dev", getOption("repos"))
# Need the latest version
if (tryCatch(packageVersion("SpaDES.project") < "0.1.1", error = function(x) TRUE)) {
  install.packages(c("SpaDES.project", "Require"), repos = repos)
}

FRU <- 30

inSim <- SpaDES.project::setupProject(
  require = "PredictiveEcology/scfmutils@development",
  packages = c("usethis", "googledrive", "httr2", "RCurl", "XML"),
  useGit=  TRUE,
  paths = list(projectPath = "NEBC",
               modulePath = file.path("modules"),
               cachePath = file.path("cache"),
               scratchPath = tempdir(),
               inputPath = file.path("inputs"),
               outputPath = file.path("outputs", paste0("FRU", FRU))
  ),
  modules = c( "PredictiveEcology/canClimateData@development",
               "PredictiveEcology/fireSense_dataPrepFit@development",
               "PredictiveEcology/Biomass_speciesData@development",
               "PredictiveEcology/Biomass_borealDataPrep@development",
              # "PredictiveEcology/Biomass_core@development",
              # "PredictiveEcology/fireSense@development",
              # "PredictiveEcology/fireSense_SpreadFit@lccFix",
              "PredictiveEcology/fireSense_IgnitionFit@development"
              # "PredictiveEcology/fireSense_EscapeFit@development"
  ),
  options = list(spades.allowInitDuringSimInit = TRUE,
                 spades.moduleCodeChecks = FALSE,
                 useCache = TRUE,
                 reproducible.inputPaths = "~/data",
                 gargle_oauth_email = "ianmseddy@gmail.com",
                 gargle_oauth_cache = "~/google_drive_cache",
                 gargle_oauth_client_type = "web", #I think?
                 reproducible.shapefileRead = "terra::vect",
                 spades.recoveryMode = 1
  ),
  times = list(start = 2011, end = 2011),
  loadOrder = unlist(modules), #load order must be passed or BBDP will be sourced prior to fsDPF.
  #also canClimateData must come before fireSense
  climateVariablesForFire = list(ignition = c("CMDsp"),
                                 spread = c("CMDsp")),
  functions = "ianmseddy/NEBC@main/R/studyAreaFuns.R",
  #update mutuallyExlcusive Cols
  studyArea = {
    sa <- scfmutils::prepInputsFireRegimePolys(destinationPath = "inputs",
                                               type = "FRU")
    sa <- sa[sa$FRU == FRU,]
    sa <- terra::vect(sa)
    sa <- terra::buffer(sa, 3000)
    sa <- terra::fillHoles(sa)
  },
  rasterToMatch = {
    rtm <- terra::rast(sa, res = c(250, 250))
    rtm[] <- 1
    rtm <- reproducible::postProcess(rtm, maskTo = sa)
  },
  rasterToMatchLarge = rasterToMatch,
  studyAreaLarge = studyArea,
  sppEquiv = {
    spp <- LandR::speciesInStudyArea(studyArea = studyArea,
                                     dPath = "inputs",)
    sppEquiv <- LandR::sppEquivalencies_CA[KNN %in% spp$speciesList,]
    sppEquiv <- sppEquiv[LANDIS_traits != "",]
    sppEquiv <- sppEquiv[grep(pattern = "Spp", x = sppEquiv$KNN, invert = TRUE),]
  },
  objectSynonyms = list("rstLCC2011" = "rstLCC"),
  params = list(
    .globals = list(.studyAreaName = paste0("FRU", FRU),
                    dataYear = 2011,
                    .plots = "png",
                    sppEquivCol = "LandR"),
    Biomass_borealDataPrep = list(
      overrideAgeInFires = FALSE,
      overrideBiomassInFires = FALSE,
      .useCache = c(".inputObjects")
    ),
    fireSense_dataPrepFit = list(".studyAreaName" = paste0("FRU", FRU)),
    canClimateData = list(".useCache" = c(".inputObjects", "init"))
  )
)


inSim$climateVariables <- list(
  historical_CMDsp = list(
    vars = "historical_CMD_sp",
    fun = quote(calcAsIs),
    .dots = list(historical_years = 1991:2022)
  )
)

devtools::load_all("../fireSenseUtils")
outSim <- SpaDES.core::simInitAndSpades2(inSim)

