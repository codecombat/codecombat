require '../../common'
Article = require '../../../../server/models/Article'

describe 'NamePlugin', ->

  article = new Article(
    name: 'Alpha'
    body: 'What does it mean?'
  )

  it 'clears things first', (done) ->
    clearModels [Article], (err) ->
      expect(err).toBeNull()
      done()

  it 'saves', (done) ->
    article.save (err) ->
      throw err if err
      done()

  it 'does not allow name conflicts', (done) ->
    c2 = new Article(
      name: 'Alpha'
      body: 'The misunderstood Greek character.'
    )

    c2.save (err) ->
      expect(err.code).toBe(409)
      done()

  it 'prevents slugs from being valid ObjectIds', (done) ->
    c2 = new Article(
      name: '522e0f149aaa330000000002'
      body: '... fish.'
    )

    c2.save (err) ->
      expect(err.code).toBe(422)
      done()

describe 'VersionedPlugin', ->
  it 'clears things first', (done) ->
    clearModels [Article], (err) ->
      expect(err).toBeNull()
      done()

  it 'can create new major versions', (done) ->
    firstArticle = new Article(name: 'List Comp1', body: "A programmer's best friend.")
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      secondObject = firstArticle.toObject()
      secondObject['body'] = 'Not as good as lambda.'

      firstArticle.makeNewMajorVersion secondObject, (err, secondArticle) ->
        throw err if err

        secondArticle.save (err) ->
          throw err if err

          thirdObject = secondArticle.toObject()
          thirdObject['body'] = '...'

          secondArticle.makeNewMajorVersion thirdObject, (err, thirdArticle) ->
            throw err if err

            thirdArticle.save ->

              Article.find {original: firstArticle.original}, (err, results) ->
                expect(results.length).toBe(3)
                expect(results[0].version.major).toBe(2)
                expect(results[1].version.major).toBe(1)
                expect(results[2].version.major).toBe(0)

                expect(results[0].version.minor).toBe(0)
                expect(results[1].version.minor).toBe(0)
                expect(results[2].version.minor).toBe(0)

                expect(results[2].version.isLatestMajor).toBe(false)
                expect(results[1].version.isLatestMajor).toBe(false)
                expect(results[0].version.isLatestMajor).toBe(true)

                expect(results[2].version.isLatestMinor).toBe(true)
                expect(results[1].version.isLatestMinor).toBe(true)
                expect(results[0].version.isLatestMinor).toBe(true)

                expect(results[2].index).toBeUndefined()
                expect(results[1].index).toBeUndefined()
                expect(results[0].index).toBe(true)

                done()

  it 'works if you do not successfully save the new major version', (done) ->
    firstArticle = new Article(name: 'List Comp2', body: "A programmer's best friend.")
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      secondObject = firstArticle.toObject()
      secondObject['body'] = 'Not as good as lambda.'

      firstArticle.makeNewMajorVersion secondObject, (err, forgottenSecondArticle) ->
        throw err if err

        firstArticle.makeNewMajorVersion secondObject, (err, realSecondArticle) ->
          throw err if err
          expect(realSecondArticle.version.major).toBe(1)
          done()

  it 'can create new minor versions', (done) ->
    firstArticle = new Article(name: 'List Comp3', body: "A programmer's best friend.")
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      secondObject = firstArticle.toObject()
      secondObject['body'] = 'Not as good as lambda.'

      firstArticle.makeNewMinorVersion secondObject, 0, (err, secondArticle) ->
        throw err if err

        secondArticle.save (err) ->
          throw err if err

          thirdObject = secondArticle.toObject()
          thirdObject['body'] = '...'

          secondArticle.makeNewMinorVersion thirdObject, 0, (err, thirdArticle) ->
            throw err if err

            thirdArticle.save ->

              Article.find {original: firstArticle.original}, (err, results) ->
                expect(results.length).toBe(3)
                expect(results[0].version.major).toBe(0)
                expect(results[1].version.major).toBe(0)
                expect(results[2].version.major).toBe(0)

                expect(results[2].version.minor).toBe(0)
                expect(results[1].version.minor).toBe(1)
                expect(results[0].version.minor).toBe(2)

                expect(results[2].version.isLatestMajor).toBe(false)
                expect(results[1].version.isLatestMajor).toBe(false)
                expect(results[0].version.isLatestMajor).toBe(true)

                expect(results[2].version.isLatestMinor).toBe(false)
                expect(results[1].version.isLatestMinor).toBe(false)
                expect(results[0].version.isLatestMinor).toBe(true)

                expect(results[2].index).toBeUndefined()
                expect(results[1].index).toBeUndefined()
                expect(results[0].index).toBe(true)

                done()

  it 'works if you do not successfully save the new minor version', (done) ->
    firstArticle = new Article(
      name: 'List Comp4',
      body: "A programmer's best friend."
      index: true
    )
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      secondObject = firstArticle.toObject()
      secondObject['body'] = 'Not as good as lambda.'

      firstArticle.makeNewMinorVersion secondObject, 0, (err, forgottenSecondArticle) ->
        throw err if err

        firstArticle.makeNewMinorVersion secondObject, 0, (err, realSecondArticle) ->
          throw err if err
          expect(realSecondArticle.version.minor).toBe(1)
          done()

  it 'works if you add a new minor version for an old major version', (done) ->
    firstArticle = new Article(name: 'List Comp4.5', body: "A programmer's best friend.")
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      secondObject = firstArticle.toObject()
      secondObject['body'] = 'Not as good as lambda.'

      firstArticle.makeNewMajorVersion secondObject, (err, secondArticle) ->
        throw err if err

        secondArticle.save (err) ->
          throw err if err

          thirdObject = secondArticle.toObject()
          thirdObject['body'] = '...'

          Article.findOne {_id: firstArticle._id}, (err, firstArticle) ->

            firstArticle.makeNewMinorVersion thirdObject, 0, (err, thirdArticle) ->
              throw err if err

              thirdArticle.save ->

                Article.find {original: firstArticle.original}, (err, results) ->
                  expect(results.length).toBe(3)
                  expect(results[2].version.major).toBe(0)
                  expect(results[1].version.major).toBe(0)
                  expect(results[0].version.major).toBe(1)

                  expect(results[2].version.minor).toBe(0)
                  expect(results[1].version.minor).toBe(1)
                  expect(results[0].version.minor).toBe(0)

                  expect(results[2].version.isLatestMajor).toBe(false)
                  expect(results[1].version.isLatestMajor).toBe(false)
                  expect(results[0].version.isLatestMajor).toBe(true)

                  expect(results[2].version.isLatestMinor).toBe(false)
                  expect(results[1].version.isLatestMinor).toBe(true)
                  expect(results[0].version.isLatestMinor).toBe(true)

                  expect(results[2].index).toBeUndefined()
                  expect(results[1].index).toBeUndefined()
                  expect(results[0].index).toBe(true)
                  done()

  it 'only keeps slugs for the absolute latest versions', (done) ->
    firstArticle = new Article(name: 'List Comp4.6', body: "A programmer's best friend.")
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      secondObject = firstArticle.toObject()
      secondObject['body'] = 'Not as good as lambda.'

      firstArticle.makeNewMajorVersion secondObject, (err, secondArticle) ->
        throw err if err

        secondArticle.save (err) ->
          throw err if err

          thirdObject = secondArticle.toObject()
          thirdObject['body'] = '...'

          Article.findOne {_id: firstArticle._id}, (err, firstArticle) ->

            firstArticle.makeNewMinorVersion thirdObject, 0, (err, thirdArticle) ->
              throw err if err

              thirdArticle.save ->

                Article.find {original: firstArticle.original}, (err, results) ->
                  expect(results.length).toBe(3)
                  expect(results[2].slug).toBeUndefined()
                  expect(results[1].slug).toBeUndefined()
                  expect(results[0].slug).toBeDefined()
                  done()


describe 'SearchablePlugin', ->
  it 'clears things first', (done) ->
    clearModels [Article], (err) ->
      expect(err).toBeNull()
      done()

  it 'can do a text search', (done) ->
    # absolutely does not work at all if you don't save an article first
    firstArticle = new Article(
      name: 'List Comp5',
      body: "A programmer's best friend.",
      index: true
    )
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      Article.find {$text: {$search: 'best'}, index: true}, (err, results) ->
        expect(err).toBeNull()
        if results
          expect(results.length).toBeGreaterThan(0)
        else
          console.log('ERROR:', err)
        done()

  it 'keeps the index property up to date', (done) ->
    firstArticle = new Article(name: 'List Comp6', body: "A programmer's best friend.")
    firstArticle.original = firstArticle._id

    firstArticle.save (err) ->
      throw err if err

      secondObject = firstArticle.toObject()
      secondObject['body'] = 'Not as good as lambda.'

      firstArticle.makeNewMinorVersion secondObject, 0, (err, secondArticle) ->
        throw err if err

        secondArticle.save (err) ->
          throw err if err

          thirdObject = secondArticle.toObject()
          thirdObject['body'] = '...'

          secondArticle.makeNewMajorVersion thirdObject, (err, thirdArticle) ->
            throw err if err

            thirdArticle.save ->
              throw err if err

              Article.find {original: firstArticle.original}, (err, results) ->
                expect(results[2].index).toBeUndefined()
                expect(results[1].index).toBeUndefined()
                expect(results[0].index).toBe(true)
                done()

  raw =
    name: 'Battlefield 1942'
    description: 'Vacation all over the world!'
    permissions: [
      target: 'not_the_public'
      access: 'owner'
    ]
