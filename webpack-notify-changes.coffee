module.exports = WebpackNotifyChanges = (options = {}) ->

WebpackNotifyChanges.prototype.apply = (compiler) ->
  compiler.plugin 'compile', (params) ->
    console.log('Saw file changes, starting build...')
  compiler.plugin 'emit', (compilation, callback) ->
    callback()
    console.log('Built!')
  
