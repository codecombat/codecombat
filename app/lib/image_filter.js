// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// Based on: http://www.html5rocks.com/en/tutorials/canvas/imagefilters/

let darkenImage, revertImage;
const Filters = {};

Filters.getPixels = function(img) {
  const c = this.getCanvas(img.naturalWidth, img.naturalHeight);
  const ctx = c.getContext('2d');
  ctx.drawImage(img, 0, 0);
  return ctx.getImageData(0, 0, c.width, c.height);
};

Filters.getCanvas = function(w, h) {
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  return c;
};

Filters.filterImage = function(filter, image, ...args) {
  args = [this.getPixels(image)].concat(args);
  return filter(...Array.from(args || []));
};

Filters.brightness = function(pixels, adjustment) {
  const d = pixels.data;
  let i = 0;
  while (i < d.length) {
    d[i] *= adjustment;
    d[i+1] *= adjustment;
    d[i+2] *= adjustment;
    i+=4;
  }
  return pixels;
};

module.exports.darkenImage = (darkenImage = function(img, borderImageSelector, pct) {
  if (pct == null) { pct = 0.5; }
  const jqimg = $(img);
  const cachedValue = jqimg.data('darkened');
  if (cachedValue) {
    $(borderImageSelector).css('border-image-source', 'url(' + cachedValue + ')');
    return img.src = cachedValue; 
  }
  if (!jqimg.data('original')) { jqimg.data('original', img.src); }
  if (!((img.naturalWidth > 0) && (img.naturalHeight > 0))) {
    console.warn('Tried to darken image', img, 'but it has natural dimensions', img.naturalWidth, img.naturalHeight);
    return img;
  }
  const imageData = Filters.filterImage(Filters.brightness, img, pct);
  const c = Filters.getCanvas(img.naturalWidth, img.naturalHeight);
  const ctx = c.getContext('2d');
  ctx.putImageData(imageData, 0, 0);
  img.src = c.toDataURL();
  $(borderImageSelector).css('border-image-source', 'url(' + img.src + ')');
  return jqimg.data('darkened', img.src);
});

module.exports.revertImage = (revertImage = function(img, borderImageSelector) {
  const jqimg = $(img);
  if (!jqimg.data('original')) { return; }
  $(borderImageSelector).css('border-image-source', 'url(' + jqimg.data('original') + ')');
  return img.src = jqimg.data('original');
});
