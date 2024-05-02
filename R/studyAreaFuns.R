#produce study area and RTM
setupSAandRTM <- function(destinationPath = "inputs", ecoprovinceNum = "14.1") {
  epUrl <- paste0("https://sis.agr.gc.ca/cansis/nsdb/ecostrat/",
                  "province/ecoprovince_shp.zip")
  ep <- reproducible::prepInputs(url =  epUrl,
                                 destinationPath = destinationPath,
                                 fun = "terra::vect")
  ep <- ep[ep$ECOPROVINC == ecoprovinceNum,]
  RTM <- prepInputs(destinationPath = destinationPath,
                    url = "https://drive.google.com/file/d/1g9jr0VrQxqxGjZ4ckF6ZkSMP-zuYzHQC/",
                    cropTo = ep, maskTo = ep,
                    filename2 = NULL,
                    method = c("near"), fun = "terra::rast")
  ep <- terra::project(ep, RTM)
  return(list(rasterToMatch = RTM, studyArea = ep))
}

makeSppEquiv <- function() {
  speciesOfConcern = c("Pice_mar", "Pice_gla", "Popu_tre",
                       "Pinu_con", "Betu_pap", "Betu_pap",
                       "Pice_eng")
  sppEquiv = LandR::sppEquivalencies_CA[LandR %in% speciesOfConcern,]
  sppEquiv$madeupFuel <- c("class3", "class3", "class2", "class4", "class3", "class2", "class3")
  return(sppEquiv)
}
