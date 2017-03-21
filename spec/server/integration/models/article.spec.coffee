require '../../common'
Article = require '../../../../server/models/Article'

describe 'Article', ->

  it 'clears things first', (done) ->
    Article.remove {}, (err) ->
      expect(err).toBeNull()
      done()

  it 'can be saved', (done) ->
    article = new Article(name: 'List Comprehension', body: "A programmer's best friend.")
    article.save (err) ->
      done()
