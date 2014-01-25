queues = require './queue'
config = require '../server_config.js'
describe 'Queue', ->
  describe 'construction interface', ->
    it 'should construct a MongoQueueClient if not in production', ->
      config.isProduction = false
      queue = queues.generateQueueClient()
      expect(queue.constructor.name).toEqual 'MongoQueueClient'
    it 'should construct an SQSQueueClient if in production', ->
      config.isProduction = true
      queue = queues.generateQueueClient()
      expect(queue.constructor.name).toEqual 'SQSQueueClient'
  describe 'registerQueue', ->
    mongoQueueClient = null
    sqsQueueClient = null
    beforeEach ->
      config.isProduction = false
      mongoQueueClient = queues.generateQueueClient()

    it 'should generate the correct type of queue', ->
      mongoQueueClient.registerQueue "TestQueue", {}, (err, data) ->
        expect(data.constructor.name).toEqual 'MongoQueue'
  describe 'sendMessage', ->
    mongoQueueClient = queues.generateQueueClient()
    testQueue = null
    it 'should send and retrieve a message', (done) ->
      mongoQueueClient.registerQueue "TestQueue", {}, (err, data) ->
        testQueue = data
        testQueue.sendMessage {"Body":"WOOOO"} ,0, (err2, data2) ->
          done()