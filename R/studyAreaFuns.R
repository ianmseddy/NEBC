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
