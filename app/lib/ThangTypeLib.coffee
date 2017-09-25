ThangTypeLib = {
  getPortraitURL: (thangTypeObj) ->
    if iconURL = thangTypeObj.rasterIcon
      return "/file/#{iconURL}"
    if rasterURL = thangTypeObj.raster
      return "/file/#{rasterURL}"
    "/file/db/thang.type/#{thangTypeObj.original}/portrait.png"
}

module.exports = ThangTypeLib
