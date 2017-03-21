client = algoliasearch("JJM5H2CHJR", "50382fc2f7fa69c67e8233ace7cd7c4c")

module.exports = 
  client: client
  schoolsIndex: client.initIndex('schools')
