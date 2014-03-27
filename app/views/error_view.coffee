View = require 'views/kinds/RootView'

module.exports = class ErrorView extends View
  id: "error-view"
  el: "<div class='alert alert-warning'></div>"

  render: ()->
  	super()
  	@$el.append("<h2><span>Error: Failed to process request.</span></h2>")