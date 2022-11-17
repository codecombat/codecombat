require('bower_components/algolia-autocomplete.js/dist/autocomplete.jquery.js');
require('bower_components/algolia-autocomplete-no-conflict/no-conflict.js');
ALGOLIA_APP_ID = "JJM5H2CHJR"
ALGOLIA_SEARCH_API_KEY = "a9cca9403c5f27b89011de2872938b69"
client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_API_KEY)

module.exports =
  client: client
  schoolsIndex: client.initIndex('schools')
