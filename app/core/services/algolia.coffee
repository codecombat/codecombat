client = algoliasearch("JJM5H2CHJR", "83e56b128e93aff5f0e69d6730270ce4")

module.exports = 
  client: client
  schoolsIndex: client.initIndex('schools')
