utils = require 'core/utils'
RootView = require 'views/core/RootView'

module.exports = class OutcomesReportResultView extends RootView
  id: 'admin-outcomes-report-result-view'
  template: require 'templates/admin/outcome-report-result-view'
  events:
    'click .back-btn': 'onClickBackButton'
    'click .print-btn': 'onClickPrintButton'
  initialize: (@options) ->
    return super() unless me.isAdmin()
    @format = _.identity
    
    if window?.Intl?.NumberFormat?
      intl = new window.Intl.NumberFormat()
      @format = intl.format.bind(intl)

    @courses = @options.courses.map (course) =>
      _.merge course, {completion: @options.courseCompletion[course._id].completion}
    super()

  onClickBackButton: ->
    console.log("Back View is", @options.backView)
    application.router.openView(@options.backView)

  onClickPrintButton: ->
    window.print()
