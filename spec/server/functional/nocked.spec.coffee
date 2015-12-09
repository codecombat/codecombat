request = require 'request'
require '../common'
config = require '../../../server_config'
nockUtils = require('../nock-utils')

xdescribe 'nock-utils', ->
  afterEach nockUtils.teardownNock

  describe 'a test using setupNock', ->
    it 'records and plays back third-party requests, but not localhost requests', (done) ->
      nockUtils.setupNock 'nock-test.json', (err, nockDone) ->
        request.get { uri: getURL('/db/level') }, (err) ->
          expect(err).toBeNull()
          t0 = new Date().getTime()
          request.get { uri: 'http://zombo.com/' }, (err) ->
            console.log 'cached speed', new Date().getTime() - t0
            expect(err).toBeNull()
            nockDone()
            done()
    
  describe 'another, sibling test that does not use setupNock', ->
    it 'is proceeds normally', (done) ->
      request.get { uri: getURL('/db/level') }, (err) ->
        expect(err).toBeNull()
        t0 = new Date().getTime()
        request.get { uri: 'http://zombo.com/' }, (err) ->
          console.log 'uncached speed', new Date().getTime() - t0
          expect(err).toBeNull()
          done()
