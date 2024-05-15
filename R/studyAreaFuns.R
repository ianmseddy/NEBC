#produce study area and RTM
setupSAandRTM <- function(destinationPath = "inputs", ecoprovinceNum = "14.1") {
  epUrl <- paste0("https://sis.agr.gc.ca/cansis/nsdb/ecostrat/",
                  "province/ecoprovince_shp.zip")
  ep <- reproducible::prepInputs(url =  epUrl,
                                 destinationPath = destinationPath,
                                 fun = "terra::vect")
  ep <- ep[ep$ECOPROVINC == ecoprovinceNum,]
  RTM <- reproducible::prepInputs(destinationPath = destinationPath,
                                  url = paste0("https://ftp.maps.canada.ca/pub/nrcan_rncan/Forests_Foret/",
                                               "canada-forests-attributes_attributs-forests-canada/",
                                               "2001-attributes_attributs-2001/",
                                               "NFI_MODIS250m_2001_kNN_Structure_Stand_Age_v1.tif"),
                    cropTo = ep, maskTo = ep,
                    filename2 = NULL,
                    method = c("near"), fun = "terra::rast")
  ep <- terra::project(ep, RTM)
  return(list(rasterToMatch = RTM, studyArea = ep))
}

makeSppEquiv <- function() {
  speciesOfConcern = c("Pice_mar", "Pice_gla", "Popu_tre",
                       "Pinu_con", "Betu_pap", "Pice_eng")
  sppEquiv = LandR::sppEquivalencies_CA[LandR %in% speciesOfConcern,]
  sppEquiv <- sppEquiv[LANDIS_traits != "PINU.CON.CON",] #drop shore pine
  sppEquiv <- sppEquiv[order(sppEquiv$LandR)]
                        # Betu_pap,  Pice_eng, Pice_gla, Pice_mar, Pinu_con, Popu_tre
  sppEquiv$madeupFuel <- c("class2", "class3", "class3", "class3", "class4", "class2")
  return(sppEquiv)
}
