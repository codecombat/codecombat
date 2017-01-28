VIEW_LOAD_LOG = false
SHOW_NOTY = false

class ViewLoadTimer
  @firstLoad: true
  constructor: (@view) ->
    @firstLoad = ViewLoadTimer.firstLoad
    ViewLoadTimer.firstLoad = false
    return unless window.performance and window.performance.now and window.performance.getEntriesByType
    @t0 = if @firstLoad then 0 else performance.now()

  setView: (@view) ->

  record: ->
    console.group('Recording view:', @view.id) if VIEW_LOAD_LOG
    views = [@view]
    networkPromises = []
    while views.length
      subView = views.pop()
      views = views.concat(_.values(subView.subviews))
      if not subView.supermodel.finished()
        networkPromises.push(subView.supermodel.finishLoading())
    console.log 'Network promises:', networkPromises.length if VIEW_LOAD_LOG

    Promise.all(networkPromises)
    .then =>
      @networkLoad = performance.now()
      return if @view.destroyed
      
      imagePromises = []
      if VIEW_LOAD_LOG
        console.groupCollapsed('Images')
        console.groupCollapsed('Skipping')
        for img in @view.$('img:not(:visible)')
          console.log img.src
        console.groupEnd()
      for img in @view.$('img:visible')
        if not img.complete
          promise = new Promise((resolve) ->
            if img.complete
              resolve()
            else
              img.onload = resolve
              img.onerror = resolve
          )
          promise.imgSrc = img.src
          console.log img.src if VIEW_LOAD_LOG
          imagePromises.push(promise)

      console.groupEnd() if VIEW_LOAD_LOG
      return Promise.all(imagePromises)
    .then =>
      return if @view.destroyed
      networkTime = @networkLoad - @t0
      totalTime = performance.now() - @t0 
      return console.warn("Unknown view at: #{document.location.href}, could not record perf.") if not @view.id
      return console.warn("Got invalid time result for view #{@view.id}: #{totalTime}, could not record perf.") if not _.isNumber(totalTime)
      tag = @view.getLoadTrackingTag?()
      m = "Loaded #{@view.id}/#{tag} in: #{totalTime}ms"

      if @firstLoad
        entries = performance.getEntriesByType('resource').filter((r) => _.string.startsWith(r.name, location.origin))
        totalEncodedBodySize = _.reduce(entries, ((total, entry) -> total + entry.encodedBodySize), 0)
        totalTransferSize = _.reduce(entries, ((total, entry) -> total + entry.transferSize), 0)
        cachedResources = _.size(_.filter(entries, (entry) -> entry.transferSize / entry.encodedBodySize < 0.1))
        totalResources = _.size(entries)
        resourceInfo = { totalEncodedBodySize, totalTransferSize, cachedResources, totalResources }
      else
        resourceInfo = {}
      
      props = _.assign({networkTime, totalTime, viewId: @view.id, @firstLoad }, resourceInfo)
      props.tag = tag if tag
      console.log m if VIEW_LOAD_LOG
      noty({text:m, type:'information', timeout: 1000, layout:'topCenter'}) if SHOW_NOTY
      window.tracker?.trackEvent 'View Load', props
    .then =>
      console.groupEnd() if VIEW_LOAD_LOG

module.exports = ViewLoadTimer
