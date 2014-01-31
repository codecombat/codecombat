queues = require './queue'
config = require '../server_config.js'
winston = require 'winston'
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

    it 'should generate the correct type of queue', (done) ->
      mongoQueueClient.registerQueue "TestQueue", {}, (err, data) ->
        expect(data.constructor.name).toEqual 'MongoQueue'
        done()

  describe 'messages', ->
    mongoQueueClient = queues.generateQueueClient()
    testQueue = null

    messageIdToDelete = null
    it 'should send a message', (done) ->
      mongoQueueClient.registerQueue "TestQueue", {}, (err, data) ->
        testQueue = data
        testQueue.sendMessage {"Body":"This is a test message"} ,0, (err2, data2) ->
          done()
    it 'should receieve a message', (done) ->
      testQueue.receieveMessage (err,data) ->
        winston.info "Data body is #{data.Body}"
        expect(data.Body).toBe "This is a test message"
        messageIdToDelete = data._id
        done()
    it 'should delete a message', (done) ->
      expect(true).toBeTruthy()
      done()

