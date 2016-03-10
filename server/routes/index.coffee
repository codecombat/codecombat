mw = require '../middleware'

module.exports.setup = (app) ->

  app.post('/auth/login-facebook', mw.auth.loginByFacebook)
  app.post('/auth/login-gplus', mw.auth.loginByGPlus)
  app.post('/auth/spy', mw.auth.spy)
  app.post('/auth/stop-spying', mw.auth.stopSpying)
  
  Article = require '../models/Article'
  app.get('/db/article', mw.rest.get(Article))
  app.post('/db/article', mw.auth.checkHasPermission(['admin', 'artisan']), mw.rest.post(Article))
  app.get('/db/article/names', mw.named.names(Article))
  app.post('/db/article/names', mw.named.names(Article))
  app.get('/db/article/:handle', mw.rest.getByHandle(Article))
  app.put('/db/article/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.put(Article))
  app.patch('/db/article/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.put(Article))
  app.post('/db/article/:handle/new-version', mw.auth.checkLoggedIn(), mw.versions.postNewVersion(Article, { hasPermissionsOrTranslations: 'artisan' }))
  app.get('/db/article/:handle/versions', mw.versions.versions(Article))
  app.get('/db/article/:handle/version/?(:version)?', mw.versions.getLatestVersion(Article))
  app.get('/db/article/:handle/files', mw.files.files(Article, {module: 'article'}))
  app.get('/db/article/:handle/patches', mw.patchable.patches(Article))
  app.post('/db/article/:handle/watchers', mw.patchable.joinWatchers(Article))
  app.delete('/db/article/:handle/watchers', mw.patchable.leaveWatchers(Article))
  
  app.get('/db/user', mw.users.fetchByGPlusID, mw.users.fetchByFacebookID)

  app.get '/db/products', require('./db/product').get
  
  TrialRequest = require '../models/TrialRequest'
  app.get('/db/trial.request', mw.trialRequests.fetchByApplicant, mw.auth.checkHasPermission(['admin']), mw.rest.get(TrialRequest))
  app.post('/db/trial.request', mw.auth.checkLoggedIn(), mw.trialRequests.post)
  app.get('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.getByHandle(TrialRequest))
  app.put('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.trialRequests.put)

  app.get '/healthcheck', (req, res) ->
    try
      async = require 'async'
      User = require '../users/User'
      async.waterfall [
        (callback) ->
          User.find({}).limit(1).exec(callback)
        , (last, callback) ->
          return("No users found") unless callback.length > 0
          User.findOne(slug: 'healthcheck').exec(callback)
        , (hcuser, callback) ->
          # Create health check user if it doesnt exist
          return callback(null, hcuser) if hcuser
          user = new User
            anonymous: false
            name: 'healthcheck'
            nameLower: 'healthcheck'
            slug: 'healthcheck'
            email: 'rob+healthcheck@codecombat.com'
            emailLower: 'rob+healthcheck@codecombat.com'
          user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/core/auth
          user.save (err) ->
            return callback(err) if err
            callback(null, user)

        , (hcuser, callback) ->
          activity = hcuser.trackActivity 'healthcheck', 1
          hcuser.update {activity: activity}, callback
      ], (err) ->
        return res.status(500).send(err.toString()) if err
        res.send("OK")
    catch error
      res.status(500).send(error.toString())
