Tracker = require 'core/Tracker'

describe 'Tracker', ->
  # Actually, we don't call updateIntercomRegularly while testing any more
  xdescribe 'updateIntercomRegularly', ->
    beforeEach ->
      window.Intercom ?= =>
      spyOn(window, 'Intercom')
      # timerCallback = jasmine.createSpy("timerCallback")
      jasmine.clock().install()

    afterEach ->
      jasmine.clock().uninstall()

    it 'calls Intercom("update") every 5 minutes until 10 times, then every 30 minutes', ->
      window.tracker.updateIntercomRegularly()
      jasmine.clock().tick(10 * 5*60*1000)
      expect(window.Intercom.calls.count()).toBe(10)
      jasmine.clock().tick(30*60*1000)
      expect(window.Intercom.calls.count()).toBe(11)
