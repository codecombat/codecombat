initSlider = ($el, startValue, changeCallback) ->
  slider = $el.slider({animate: 'fast'})
  slider.slider('value', startValue)
  slider.on('slide', changeCallback)
  slider.on('slidechange', changeCallback)
  slider

module.exports = initSlider
