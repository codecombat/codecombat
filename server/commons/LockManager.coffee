config = require '../../server_config'
redis = require 'redis'
class LockManager
  constructor: ->
    unless config.isProduction or config.redis.host isnt "localhost"
      throw "You shouldn't be instantiating distributed locks unless in production."
    @redisClient = redis.createClient config.redis.port, config.redis.host
    @lockValues = {}
    @unlockScript = "if redis.call(\"get\",KEYS[1]) == ARGV[1] then return redis.call(\"del\",KEYS[1]) else return 0 end"
  
  setLock: (lockName, timeoutMs, cb) =>
    randomNumber = Math.floor(Math.random() * 1000000000)
    @redisClient.set [lockName,randomNumber, "NX", "PX", timeoutMs], (err, res) ->
      if err? then return cb err, null
      @lockValues[lockName] = randomNumber
      cb null, res
      
  releaseLock: (lockName, cb) =>
    @redisClient.eval [@unlockScript, 1, lockName, @lockValues[lockName]], (err, res) -> 
      if err? then return cb err, null
      #1 represents success, 0 failure
      cb null, Boolean(Number(res))
  
module.exports = new RedisLock() 