fetchJson = require './fetch-json'

module.exports = {
  getAll: (options={}) ->
    fetchJson("/db/campaign", options)
  get: ({ campaignHandle }, options={}) ->
    fetchJson("/db/campaign/#{campaignHandle}", options)
  fetchGameContent: (campaignHandle, options={}) ->
    fetchJson("/db/campaign/#{campaignHandle}/game-content", options)
}
