require '../common'

describe 'schema methods', ->
  patch = new Patch
    delta:
      scripts: 0: i18n: 'aaahw yeahh'
      _t: 'a'

  it 'is translation patch', ->
    expect(patch.isTranslationPatch()).toBeTruthy()
    patch.set 'delta.i18n', undefined
    expect(patch.isTranslationPatch()).toBeFalsy()

  it 'is miscellaneous patch', ->
    expect(patch.isMiscPatch()).toBeTruthy()
    patch.set 'delta.thangs', undefined
    expect(patch.isMiscPatch()).toBeFalsy()




