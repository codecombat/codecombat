fetchJson = require './fetch-json'

module.exports = {
  getDirectory: ({path}, options={}) ->
    unless _.string.endsWith(path, '/')
      path = path + '/'
    fetchJson("/file/#{path}", options).then((res) -> return JSON.parse(res))
    
  saveFile: ({url, filename, mimetype, path, force}, options={}) ->
    fetchJson('/file', _.assign({}, options, {
      method: 'POST'
      json: { url, filename, mimetype, path, force }
    }))
}
