ThangTypeLib = {
  getPortraitURL: (thangTypeObj) ->
    return '' if application.testing
    if iconURL = @get('rasterIcon')
      return "/file/#{iconURL}"
    if rasterURL = @get('raster')
      return "/file/#{rasterURL}"
    "/file/db/thang.type/#{@get('original')}/portrait.png"
}

module.exports = ThangTypeLib
