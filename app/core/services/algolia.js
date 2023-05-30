// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
window.algoliasearch = require('algoliasearch');
require('bower_components/algolia-autocomplete.js/dist/autocomplete.jquery.js');
require('bower_components/algolia-autocomplete-no-conflict/no-conflict.js');
const ALGOLIA_APP_ID = "JJM5H2CHJR";
const ALGOLIA_SEARCH_API_KEY = "a9cca9403c5f27b89011de2872938b69";
const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_API_KEY);

module.exports = {
  client,
  schoolsIndex: client.initIndex('schools')
};
