getOrUpdatePkg <- function(p, minVer, repo) {
  if (!isFALSE(try(packageVersion(p) < minVer, silent = TRUE) )) {
    if (missing(repo)) repo = c("predictiveecology.r-universe.dev", getOption("repos"))
    install.packages(p, repos = repo)
  }
}

getOrUpdatePkg("Require", "0.3.1.9015")
getOrUpdatePkg("SpaDES.project", "0.0.8.9040")
getOrUpdatePkg("LandR", "1.1.0.9079")

# removed library(SpaDES.project) -- just cleaner, personal preference
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
  modules = c(
    "ianmseddy/gmcsDataPrep@development"
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
    gmcsDataPrep = list(PSPdataTypes = c("BC", "AB", "NFI"))
  ),
  functions = "ianmseddy/Edehzhie@main/R/setupFuns.R",
  speciesOfConcern = c("Pice_mar", "Pice_gla", "Popu_tre",
                       "Pinu_con", "Betu_pap", "Betu_pap",
                       "Pice_eng"),
  sppEquiv = LandR::sppEquivalencies_CA[LandR %in% speciesOfConcern,],
  studyArea = setupSAandRTM()$studyArea,
  rasterToMatch = setupSAandRTM()$rasterToMatch,
  studyAreaPSP = setupSAandRTM(ecoprovinceNum = c("14.1", "14.2", "14.3", "14.4"))$studyArea,
  packages = "googledrive",
  require = c("PredictiveEcology/reproducible@modsForLargeArchives (HEAD)"),
  useGit = TRUE
)

inSim <- do.call(SpaDES.core::simInitAndSpades, out)
