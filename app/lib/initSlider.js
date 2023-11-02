/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const initSlider = function($el, startValue, changeCallback) {
  const slider = $el.slider({animate: 'fast'});
  slider.slider('value', startValue);
  slider.on('slide', changeCallback);
  slider.on('slidechange', changeCallback);
  return slider;
};

module.exports = initSlider;
