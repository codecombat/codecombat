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
    @redisClient.set [lockName,randomNumber, "NX", "PX", timeoutMs], (err, res) =>
      if err? then return cb err, null
      if res is "OK"
        @lockValues[lockName] = randomNumber
        return cb null, "Lock set!"
      unless res 
        return cb "Lock already set!", null
      
  releaseLock: (lockName, cb) =>
    @redisClient.eval [@unlockScript, 1, lockName, @lockValues[lockName]], (err, res) -> 
      if err? then return cb err, null
      if res
        cb null, "The lock was released!"
      else
        cb "The lock was not released.", null

module.exports = new LockManager() 
