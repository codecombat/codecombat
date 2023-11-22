// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const VIEW_LOAD_LOG = false
const SHOW_NOTY = false

class ViewLoadTimer {
  static initClass () {
    this.firstLoad = true
  }

  constructor (view) {
    this.view = view
    this.firstLoad = ViewLoadTimer.firstLoad
    ViewLoadTimer.firstLoad = false
    if (!window.performance || !window.performance.now || !window.performance.getEntriesByType) { return }
    this.t0 = this.firstLoad ? 0 : performance.now()
  }

  setView (view) {
    this.view = view
  }

  record () {
    let networkPromises
    if (VIEW_LOAD_LOG) { console.group('Recording view:', this.view.id) }

    // Static pages do not measure resource loading
    if (this.firstLoad && application.loadedStaticPage && me.isAnonymous()) {
      this.skippingNetworkResources = true
      networkPromises = []
    } else {
      let views = [this.view]
      networkPromises = []
      while (views.length) {
        const subView = views.pop()
        views = views.concat(_.values(subView.subviews))
        if (!subView.supermodel.finished()) {
          networkPromises.push(subView.supermodel.finishLoading())
        }
      }
    }
    if (VIEW_LOAD_LOG) { console.log('Network promises:', networkPromises.length) }
    const thatThereId = this.view.id
    return Promise.all(networkPromises)
      .then(() => {
        let img
        this.networkLoad = performance.now()
        if (this.view.destroyed) { return }

        const imagePromises = []
        if (VIEW_LOAD_LOG) {
          console.groupCollapsed('Images')
          console.groupCollapsed('Skipping (not :visible)')
          for (img of Array.from(this.view.$('img:not(:visible)'))) {
            console.log(img.src)
          }
          console.groupEnd()
        }
        for (img of Array.from(this.view.$('img:visible'))) {
          if (!img.complete) {
            const promise = new Promise(function (resolve) {
              if (img.complete) {
                return resolve()
              } else {
                img.onload = resolve
                img.onerror = resolve
              }
            })
            promise.imgSrc = img.src
            imagePromises.push(promise)
          }
          if (VIEW_LOAD_LOG) { console.log(img.src, (img.complete ? '' : '(still loading)')) }
        }

        if (VIEW_LOAD_LOG) { console.groupEnd() }
        this.imagesAlreadyLoaded = imagePromises.length === 0
        return Promise.all(imagePromises)
      }).then(() => {
        let networkTime, resourceInfo
        let endTime = performance.now()
        if (this.imagesAlreadyLoaded && this.skippingNetworkResources) {
        // if JS loads after a static page load and all images are already loaded,
        // use performance resources to determine endTime and, by extension, totalTime
          const imageResponseEnds = performance.getEntriesByType('resource')
          // TODO Performance: Consider recording when just the CSS is finished, too
            .filter(r => _.contains(['img', 'css'], r.initiatorType))
            .map(r => r.responseEnd)
          if (VIEW_LOAD_LOG) { console.log('Static page measures endTime as', Math.max(...Array.from(imageResponseEnds || [])).toFixed(1), 'instead of', endTime.toFixed(1)) }
          endTime = Math.max(...Array.from(imageResponseEnds || []))
        }

        if (this.skippingNetworkResources) {
        // if there were no network resources, or we didn't count them for static pages,
        // use domInteractive instead
          if (VIEW_LOAD_LOG) { console.log('No network requests; Measuring networkTime as (domInteractive - navigationStart)') }
          networkTime = performance.timing.domInteractive - performance.timing.navigationStart
        } else {
          networkTime = this.networkLoad - this.t0
        }
        if (VIEW_LOAD_LOG) { console.log(`networkTime: ${networkTime}`) }
        const totalTime = endTime - this.t0
        if (VIEW_LOAD_LOG) { console.log(`totalTime: ${totalTime}`) }
        if (VIEW_LOAD_LOG) { console.log('Saw view load event', thatThereId, this.view.id) }

        if (this.view.destroyed) {
          if (VIEW_LOAD_LOG) { console.log('Sure did toss that thing.') }
          window.bored += totalTime
          return
        }
        if (!this.view.id) { return console.warn(`Unknown view at: ${document.location.href}, could not record perf.`) }
        if (!_.isNumber(totalTime)) { return console.warn(`Got invalid time result for view ${this.view.id}: ${totalTime}, could not record perf.`) }
        const tag = typeof this.view.getLoadTrackingTag === 'function' ? this.view.getLoadTrackingTag() : undefined
        const m = `Loaded ${this.view.id}/${tag} in: ${totalTime.toFixed(1)}ms`

        if (this.firstLoad) {
          const entries = performance.getEntriesByType('resource').filter(r => _.string.startsWith(r.name, location.origin))
          const essentialEntries = _.filter(entries, entry => {
            if (/vimeo/.test(entry.name)) { return false }
            if (/TestView/.test(entry.name)) { return false }
            if (/file\/db\//.test(entry.name)) { return false } // Don't count DB images
            if (/\/db\/analytics\.log\.event/.test(entry.name)) { return false } // Don't count analytics events
            if (/\/db\//.test(entry.name)) { return true } // Do count DB data
            if (/chunks\/.*bundle.js/.test(entry.name)) { return true }
            if (/app.js/.test(entry.name)) { return true }
            if (/boot.js/.test(entry.name)) { return true }
            if (/ace/.test(entry.name)) { return true }
            if (/esper/.test(entry.name)) { return true }
            if (/aether/.test(entry.name)) { return true }
            if (/esper.modern.js/.test(entry.name)) { return true }
            if (/lodash.js/.test(entry.name)) { return true }
            if (/run-tests.js/.test(entry.name)) { return true }
            if (/setImmediate.js/.test(entry.name)) { return true }
            if (/web-dev-listener.js/.test(entry.name)) { return true }
            if (/world/.test(entry.name)) { return true }
            if (/app.css/.test(entry.name)) { return true }
            return false
          })
          if (VIEW_LOAD_LOG) {
            _.each({
              'All resources': entries,
              'Essential resources': essentialEntries
            }, function (entryList, groupLabel) {
              console.groupCollapsed(groupLabel)
              console.log('(transferSize in bytes: file path)')
              for (const entry of Array.from(entryList)) { console.log(`${entry.transferSize}: ${entry.name}`) }
              return console.groupEnd()
            })
          }
          const totalEncodedBodySize = _.reduce(entries, (total, entry) => total + entry.encodedBodySize, 0)
          const totalEssentialEncodedBodySize = _.reduce(essentialEntries, (total, entry) => total + entry.encodedBodySize, 0)
          const totalTransferSize = _.reduce(entries, (total, entry) => total + entry.transferSize, 0)
          const totalEssentialTransferSize = _.reduce(essentialEntries, (total, entry) => total + entry.transferSize, 0)
          if (VIEW_LOAD_LOG) { console.log(`totalTransferSize: ${totalTransferSize}`) }
          if (VIEW_LOAD_LOG) { console.log(`totalEssentialTransferSize: ${totalEssentialTransferSize}`) }
          const cachedResources = _.size(_.filter(entries, entry => (entry.transferSize / entry.encodedBodySize) < 0.1))
          const cachedEssentialResources = _.size(_.filter(essentialEntries, entry => (entry.transferSize / entry.encodedBodySize) < 0.1))
          const totalResources = _.size(entries)
          const totalEssentialResources = _.size(essentialEntries)
          resourceInfo = {
            totalEncodedBodySize,
            totalTransferSize,
            cachedResources,
            totalResources,
            totalEssentialEncodedBodySize,
            totalEssentialTransferSize,
            cachedEssentialResources,
            totalEssentialResources
          }
        } else {
          resourceInfo = {}
        }

        const props = _.assign({ networkTime, totalTime, viewId: this.view.id, firstLoad: this.firstLoad }, resourceInfo)
        if (tag) { props.tag = tag }
        window.performanceInfo = props
        if (window.performance != null ? window.performance.memory : undefined) {
        // TODO: Consider attaching memory info to the analytics event as well.
          _.assign(window.performanceInfo, _.pick(window.performance.memory, () => true))
        }
        if (VIEW_LOAD_LOG) { console.log(m) }
        if (SHOW_NOTY) { noty({ text: m, type: 'information', timeout: 1000, layout: 'topCenter' }) }
        if (window.tracker != null) {
          window.tracker.trackEvent('View Load', props)
        }
        if (window.timeSpendWaiting == null) { window.timeSpendWaiting = 0 }
        window.timeSpendWaiting += totalTime
        return window.timeSpendWaiting
      }).then(() => {
        if (VIEW_LOAD_LOG) { return console.groupEnd() }
      })
  }
}
ViewLoadTimer.initClass()

module.exports = ViewLoadTimer
