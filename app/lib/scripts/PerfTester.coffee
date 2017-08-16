
class Agent
  constructor: () ->
    @$iframe = $('<iframe id="frame" src="/nothing.html"></iframe>')
    @iframe = @$iframe[0]

  clear: () ->
    @navigate('/nothing.html').then () =>
      @iframe.contentWindow.performance.clearResourceTimings()
      @iframe.contentWindow.performance.clearMeasures()

  navigate: (url) ->
    new Promise (res, rej) =>
      @$iframe.one 'load', (e) =>
        @iframe.contentWindow.performance.setResourceTimingBufferSize(1000)
        delete window.bored
        res()
      @iframe.contentWindow.location.href = url
  waitForCodeCombatLoaded: () ->
    new Promise (res, rej) =>
      console.log "Hooking Router"
      @iframe.contentWindow.application.router.once 'did-load-route', () ->
        #TODO: Wait for supermodel to be loaded.
        res()

  wait: (time) ->
    new Promise (res, rej) ->
      setTimeout res, time

  waitForAllImagesToBeLoaded: () ->
    $jq = @iframe.contentWindow.$
    imagePromises = []
    for img in $jq('img:visible')
      if not img.complete
        promise = new Promise((resolve) ->
          if img.complete
            resolve()
          else
            img.onload = resolve
            img.onerror = resolve
        )
        promise.imgSrc = img.src
        console.log "Waiting on", img.src
        imagePromises.push(promise)
    return Promise.all(imagePromises)

  findAndWait: (what) =>
    target = @iframe.contentWindow.$(what)
    if target.length < 1
      #console.log "Cant find #{what}, waiting..."
      return @wait(5).then () => @findAndWait(what)
    else
      return new Promise (res, rej) -> res(target)

  clickAndWaitForRoute: (what) =>
    @findAndWait(what).then (target) =>
      new Promise (res, rej) =>
        target.click()
        @iframe.contentWindow.application.router.once 'did-load-route', () ->
          #TODO: Wait for supermodel to be loaded.
          res()
        target.click()

  click: (what) =>
    @findAndWait(what).then (target) =>
      target.click()

  ensureComplete: () =>
    state = @iframe.contentDocument.readyState
    if state isnt 'complete'
      console.log "Incomplete, waiting..."
      return @wait(5).then () => @ensureComplete()
    else
      console.log "Document state is complete"
      return new Promise (res, rej) -> res()

  retreiveTimings: () ->
    unless @iframe.contentWindow.bored
      return @wait(1).then () => @retreiveTimings()
    new Promise (res, rej) =>
      res({
        timing: @iframe.contentWindow.performance.timing.toJSON(),
        resources: @iframe.contentWindow.performance.getEntriesByType("resource").map (x) -> x.toJSON()
        now: @iframe.contentWindow.performance.now()
        reportedByOurTracking: @iframe.contentWindow.timeSpendWaiting
      })

module.exports = class PerfTester extends Backbone.View
  events:
    'click .go': 'go'

  constructor: () ->
    super arguments...

   log: (what) =>
     console.log what
     ts = String(Math.floor(performance.now() - @base))
     ts = new Array(7 - ts.length).join(' ') + ts if ts.length < 6
     @$logout.prepend('<div>[<span style="color: cyan">' + ts + '</span> ms] '  + what + '</div>')

  initialize: () ->
    window.currentView = @
    @agent = new Agent
    @$iframe = @agent.$iframe
    @iframe = @agent.iframe
    @$holder = $('<div id="holder"></div>')
    @$holder.append @$iframe
    @$logout = $('<div id="logout"></div>')
    @render()

  render: () ->
    @$el.empty()
    
    @$el.append @$logout
    @$el.append @$holder
    @$el.append $('<button class="go btn btn-primary">Go</button>')
    #setTimeout @go, 1000
  
  go: () =>
    n = 1
    tests = Object.keys(@tests).slice(n, n+1)
    results = {}
    #tests = ['directToLibraryTact']
    next = () =>
      return if tests.length < 1 
      test = tests.shift()
      @base = performance.now()
      @log "<b>--> Executing test #{test}</b>"
      ts = 0
      @agent.clear().then () =>
        @tests[test](@agent, @log).then () =>
          ts = String(Math.ceil(performance.now() - @base))
          @agent.retreiveTimings()
        .then (timings) =>
          bw = timings.resources.map((x) => x.transferSize).reduceRight((a,b) -> b + a )/1024/1024
          weight = timings.resources.map((x) => x.decodedBodySize).reduceRight((a,b) -> b + a )/1024/1024
          results[test] = {time: ts, bw, weight}
          @log "<b>--> Finished test #{test} in #{ts}ms, bandwidth #{bw.toFixed(2)}mb, page weight #{weight.toFixed(2)}mb</b>"
          @log "x Tracked Time Waiting: #{timings.reportedByOurTracking} ms?"
          console.log timings
        .then next
      

    @$logout.empty()
    next().then () =>
      #@agent.clear()
      @base = performance.now()
      @log "All Tests Done!"
      console.log results
      @log "  #{k} => #{v.time}ms | T: #{v.bw} | W: #{v.weight}" for k, v of results



  tests:
    homepageLoad: (agent, log) =>
      agent.navigate('/')
      .then () -> agent.findAndWait('#classroom-in-box-container')
      .then () -> agent.waitForAllImagesToBeLoaded()
      .then () ->
        agent.retreiveTimings()
      .then (data) =>
        time = data.timing.loadEventEnd - data.timing.navigationStart
        ttfb = data.timing.responseStart - data.timing.navigationStart
        console.log ttfb
        log "Loaded first page in #{time}ms"
        log "Time to first byte was #{ttfb}ms"
        for k of data.timing
          delta = data.timing[k] - data.timing.navigationStart
          log "    #{k}: #{delta}" if delta > 0


    homepageToPlaying: (agent, log) =>
      agent.navigate('/')
      .then () =>
        agent.clickAndWaitForRoute('a[href="/play"]')
      .then () -> agent.click('div.dungeon btn')
      .then () -> log "Got to overworld"
      .then () -> agent.ensureComplete()
      .then () -> agent.click('a[data-level-slug="dungeons-of-kithgard"]:visible') 
      .then () -> agent.click('button.start-level:visible')
      .then () -> log "Got to dungeon"
      .then () -> agent.ensureComplete()
      .then () -> agent.click('div.available > button')
      .then () -> log "Gear loaded"
      .then () -> agent.click('#play-level-button:visible')
      .then () -> agent.click('button.start-level-button:visible')
      .then () =>
        agent.retreiveTimings()
      .then (data) ->
        log "playing game"

    directToLibraryTact: (agent, log) =>
      agent.navigate('play/level/library-tactician')
      .then () -> agent.click('#close-modal:visible') 
      .then () -> agent.click('button.start-level-button:visible') 

    privacyLoad: (agent, log) =>
      agent.navigate('/privacy')

