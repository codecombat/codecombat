# Based on: http://www.html5rocks.com/en/tutorials/canvas/imagefilters/

Filters = {}

Filters.getPixels = (img) ->
  c = @getCanvas(img.naturalWidth, img.naturalHeight)
  ctx = c.getContext('2d')
  ctx.drawImage(img, 0, 0)
  return ctx.getImageData(0, 0, c.width, c.height)

Filters.getCanvas = (w, h) ->
  c = document.createElement('canvas')
  c.width = w
  c.height = h
  return c

Filters.filterImage = (filter, image, args...) ->
  args = [this.getPixels(image)].concat(args)
  return filter(args...)

Filters.brightness = (pixels, adjustment) ->
  d = pixels.data
  i = 0
  while i < d.length
    d[i] *= adjustment
    d[i+1] *= adjustment
    d[i+2] *= adjustment
    i+=4
  return pixels

module.exports.darkenImage = darkenImage = (img, pct=0.5) ->
  jqimg = $(img)
  cachedValue = jqimg.data('darkened')
  return img.src = cachedValue if cachedValue
  jqimg.data('original', img.src) unless jqimg.data('original')
  if not (img.naturalWidth > 0 and img.naturalHeight > 0)
    console.warn 'Tried to darken image', img, 'but it has natural dimensions', img.naturalWidth, img.naturalHeight
    return img
  imageData = Filters.filterImage(Filters.brightness, img, pct)
  c = Filters.getCanvas(img.naturalWidth, img.naturalHeight)
  ctx = c.getContext('2d')
  ctx.putImageData(imageData, 0, 0)
  img.src = c.toDataURL()
  jqimg.data('darkened', img.src)

module.exports.revertImage = revertImage = (img) ->
  jqimg = $(img)
  return unless jqimg.data('original')
  img.src = jqimg.data('original')
