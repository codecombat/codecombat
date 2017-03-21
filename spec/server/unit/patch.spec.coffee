require '../common'
Patch = require '../../../server/models/Patch'


describe 'schema methods', ->
  patch = new Patch
    commitMessage: 'Accept this patch!'
    editPath: '/who/knows/yes'
    target:
      id:null
      collection: 'article'
    delta:
      "scripts":
        "0":
          "noteChain":
            "1":
              "sprites":
                "0":
                  "say":
                    "i18n":
                      "nl-BE": [ "text": "aaahw yeahh" ]
                "_t": "a"
            "_t": "a"
        "_t": "a"
      "thangs":
        "111": [
          "components": [
            "config": {
              "stateless": true
            }
          ]
        ]
        "_t": "a"

  it 'is translation patch', ->
    expect(patch.isTranslationPatch()).toBeTruthy()
    patch.set 'delta.scripts', undefined
    expect(patch.isTranslationPatch()).toBeFalsy()

  it 'is miscellaneous patch', ->
    expect(patch.isMiscPatch()).toBeTruthy()
    patch.set 'delta.thangs', undefined
    expect(patch.isMiscPatch()).toBeFalsy()




