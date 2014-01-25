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
      config.isProduction = true
      sqsQueueClient = queues.generateQueueClient()

    it 'should generate the correct type of queue', ->
      mongoQueueClient.registerQueue "TestQueue", {}, (err, data) ->
        expect(data.constructor.name).toEqual 'MongoQueue'

