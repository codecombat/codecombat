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

    # Static pages do not measure resource loading
    if @firstLoad and application.loadedStaticPage and me.isAnonymous()
      @skippingNetworkResources = true
      networkPromises = []
    else
      views = [@view]
      networkPromises = []
      while views.length
        subView = views.pop()
        views = views.concat(_.values(subView.subviews))
        if not subView.supermodel.finished()
          networkPromises.push(subView.supermodel.finishLoading())
    console.log 'Network promises:', networkPromises.length if VIEW_LOAD_LOG
    thatThereId = @view.id
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
      @imagesAlreadyLoaded = imagePromises.length is 0
      return Promise.all(imagePromises)
    .then =>
      endTime = performance.now()
      if @imagesAlreadyLoaded and @skippingNetworkResources
        # if JS loads after a static page load and all images are already loaded,
        # use performance resources to determine endTime and, by extension, totalTime
        imageResponseEnds = performance.getEntriesByType('resource')
          .filter((r) => _.string.endsWith(r.initiatorType, 'img'))
          .map((r) => r.responseEnd)
        endTime = Math.max(imageResponseEnds...)

      if @skippingNetworkResources
        # if there were no network resources, or we didn't count them for static pages,
        # use domInteractive instead
        networkTime = performance.timing.domInteractive - performance.timing.navigationStart
      else
        networkTime = @networkLoad - @t0
      totalTime = endTime - @t0 
      console.log "Saw view load event", thatThereId, @view.id

      if @view.destroyed
        console.log "Sure did toss that thing."
        window.bored += totalTime
        return
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
      window.timeSpendWaiting ?= 0
      window.timeSpendWaiting += totalTime

    .then =>
      console.groupEnd() if VIEW_LOAD_LOG

module.exports = ViewLoadTimer
