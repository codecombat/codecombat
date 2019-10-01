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
        console.groupCollapsed('Skipping (not :visible)')
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
          imagePromises.push(promise)
        console.log img.src, (if img.complete then "" else "(still loading)") if VIEW_LOAD_LOG

      console.groupEnd() if VIEW_LOAD_LOG
      @imagesAlreadyLoaded = imagePromises.length is 0
      return Promise.all(imagePromises)
    .then =>
      endTime = performance.now()
      if @imagesAlreadyLoaded and @skippingNetworkResources
        # if JS loads after a static page load and all images are already loaded,
        # use performance resources to determine endTime and, by extension, totalTime
        imageResponseEnds = performance.getEntriesByType('resource')
          # TODO Performance: Consider recording when just the CSS is finished, too
          .filter((r) => _.contains(['img', 'css'], r.initiatorType))
          .map((r) => r.responseEnd)
        console.log('Static page measures endTime as', Math.max(imageResponseEnds...).toFixed(1), 'instead of', endTime.toFixed(1)) if VIEW_LOAD_LOG
        endTime = Math.max(imageResponseEnds...)

      if @skippingNetworkResources
        # if there were no network resources, or we didn't count them for static pages,
        # use domInteractive instead
        console.log "No network requests; Measuring networkTime as (domInteractive - navigationStart)" if VIEW_LOAD_LOG
        networkTime = performance.timing.domInteractive - performance.timing.navigationStart
      else
        networkTime = @networkLoad - @t0
      console.log "networkTime: #{networkTime}" if VIEW_LOAD_LOG
      totalTime = endTime - @t0
      console.log "totalTime: #{totalTime}" if VIEW_LOAD_LOG
      console.log "Saw view load event", thatThereId, @view.id

      if @view.destroyed
        console.log "Sure did toss that thing."
        window.bored += totalTime
        return
      return console.warn("Unknown view at: #{document.location.href}, could not record perf.") if not @view.id
      return console.warn("Got invalid time result for view #{@view.id}: #{totalTime}, could not record perf.") if not _.isNumber(totalTime)
      tag = @view.getLoadTrackingTag?()
      m = "Loaded #{@view.id}/#{tag} in: #{totalTime.toFixed(1)}ms"

      if @firstLoad
        entries = performance.getEntriesByType('resource').filter((r) => _.string.startsWith(r.name, location.origin))
        essentialEntries = _.filter(entries, (entry) =>
          return false if /vimeo/.test(entry.name)
          return false if /TestView/.test(entry.name)
          return false if /file\/db\//.test(entry.name) # Don't count DB images
          return false if /\/db\/analytics\.log\.event/.test(entry.name) # Don't count analytics events
          return true if /\/db\//.test(entry.name) # Do count DB data
          return true if /chunks\/.*bundle.js/.test(entry.name)
          return true if /app.js/.test(entry.name)
          return true if /boot.js/.test(entry.name)
          return true if /ace/.test(entry.name)
          return true if /esper/.test(entry.name)
          return true if /aether/.test(entry.name)
          return true if /esper.modern.js/.test(entry.name)
          return true if /lodash.js/.test(entry.name)
          return true if /run-tests.js/.test(entry.name)
          return true if /setImmediate.js/.test(entry.name)
          return true if /web-dev-listener.js/.test(entry.name)
          return true if /world/.test(entry.name)
          return true if /app.css/.test(entry.name)
          return false
        )
        if VIEW_LOAD_LOG
          _.each {
            'All resources': entries
            'Essential resources': essentialEntries
          }, (entryList, groupLabel) ->
            console.groupCollapsed groupLabel
            console.log "(transferSize in bytes: file path)"
            console.log "#{entry.transferSize}: #{entry.name}" for entry in entryList
            console.groupEnd()
        totalEncodedBodySize = _.reduce(entries, ((total, entry) -> total + entry.encodedBodySize), 0)
        totalEssentialEncodedBodySize = _.reduce(essentialEntries, ((total, entry) -> total + entry.encodedBodySize), 0)
        totalTransferSize = _.reduce(entries, ((total, entry) -> total + entry.transferSize), 0)
        totalEssentialTransferSize = _.reduce(essentialEntries, ((total, entry) -> total + entry.transferSize), 0)
        console.log "totalTransferSize: #{totalTransferSize}" if VIEW_LOAD_LOG
        console.log "totalEssentialTransferSize: #{totalEssentialTransferSize}" if VIEW_LOAD_LOG
        cachedResources = _.size(_.filter(entries, (entry) -> entry.transferSize / entry.encodedBodySize < 0.1))
        cachedEssentialResources = _.size(_.filter(essentialEntries, (entry) -> entry.transferSize / entry.encodedBodySize < 0.1))
        totalResources = _.size(entries)
        totalEssentialResources = _.size(essentialEntries)
        resourceInfo = { totalEncodedBodySize, totalTransferSize, cachedResources, totalResources,
          totalEssentialEncodedBodySize, totalEssentialTransferSize, cachedEssentialResources, totalEssentialResources }
      else
        resourceInfo = {}
      
      props = _.assign({networkTime, totalTime, viewId: @view.id, @firstLoad }, resourceInfo)
      props.tag = tag if tag
      window.performanceInfo = props;
      if window.performance?.memory
        # TODO: Consider attaching memory info to the analytics event as well.
        _.assign window.performanceInfo, _.pick(window.performance.memory, =>true)
      console.log m if VIEW_LOAD_LOG
      noty({text:m, type:'information', timeout: 1000, layout:'topCenter'}) if SHOW_NOTY
      window.tracker?.trackEvent 'View Load', props
      window.timeSpendWaiting ?= 0
      window.timeSpendWaiting += totalTime

    .then =>
      console.groupEnd() if VIEW_LOAD_LOG

module.exports = ViewLoadTimer
