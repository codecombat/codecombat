const { versionFromSearch, versionLabel, resolveVersion, isStale, editUrl } = require('lib/scenario-version')

describe('lib/scenario-version', function () {
  const ORIGINAL = '6adb146e0e103758a145abb2'
  const v0 = { _id: ORIGINAL, original: ORIGINAL, slug: 'fabricator-training', version: { major: 0, minor: 0 } }
  const v3 = { _id: '6adc000000000000000000a3', original: ORIGINAL, slug: 'fabricator-training', version: { major: 0, minor: 3 } }
  const latest = { _id: '6adf50523c6ce3962e63cf56', original: ORIGINAL, slug: 'fabricator-training', version: { major: 0, minor: 15 } }

  describe('versionFromSearch', function () {
    it('reads a major.minor version from the query', function () {
      expect(versionFromSearch('?version=0.3')).toBe('0.3')
      expect(versionFromSearch('?foo=1&version=12.7#top')).toBe('12.7')
    })

    it('ignores a missing or malformed version', function () {
      expect(versionFromSearch('')).toBeNull()
      expect(versionFromSearch(undefined)).toBeNull()
      expect(versionFromSearch('?version=')).toBeNull()
      expect(versionFromSearch('?version=latest')).toBeNull()
      expect(versionFromSearch('?version=1')).toBeNull()
      expect(versionFromSearch('?version=0.3.1')).toBeNull()
    })
  })

  describe('versionLabel', function () {
    it('formats major.minor and gives null without a version', function () {
      expect(versionLabel(v3)).toBe('0.3')
      expect(versionLabel({ _id: 'x' })).toBeNull()
      expect(versionLabel(null)).toBeNull()
    })
  })

  describe('resolveVersion', function () {
    it('edits the latest when the handle is the original id', function () {
      expect(resolveVersion({ handle: ORIGINAL, loaded: v0, version: null })).toBe('latest')
    })

    it('keeps a document loaded by slug', function () {
      expect(resolveVersion({ handle: 'fabricator-training', loaded: latest, version: null })).toBeNull()
    })

    it('keeps an old version loaded by its own id, so Version history still opens it', function () {
      expect(resolveVersion({ handle: v3._id, loaded: v3, version: null })).toBeNull()
    })

    it('opens v0.0 on the original id when ?version asks for it', function () {
      expect(resolveVersion({ handle: ORIGINAL, loaded: v0, version: '0.0' })).toBeNull()
    })

    it('loads the exact version ?version names when it is not the loaded one', function () {
      expect(resolveVersion({ handle: ORIGINAL, loaded: v0, version: '0.3' })).toBe('exact')
      expect(resolveVersion({ handle: 'fabricator-training', loaded: latest, version: '0.3' })).toBe('exact')
    })

    it('keeps the latest when ?version names it', function () {
      expect(resolveVersion({ handle: 'fabricator-training', loaded: latest, version: '0.15' })).toBeNull()
    })

    it('does nothing without a loaded document', function () {
      expect(resolveVersion({ handle: ORIGINAL, loaded: null, version: null })).toBeNull()
    })
  })

  describe('isStale', function () {
    it('compares ids, not version flags', function () {
      expect(isStale(v3, latest)).toBe(true)
      expect(isStale(latest, Object.assign({}, latest, { version: { major: 0, minor: 99 } }))).toBe(false)
      expect(isStale(v3, null)).toBe(false)
      expect(isStale(null, latest)).toBe(false)
    })
  })

  describe('editUrl', function () {
    it('prefers the slug, then the original id, and adds ?version only when asked', function () {
      expect(editUrl(latest)).toBe('/editor/ai-scenario/fabricator-training')
      expect(editUrl({ _id: v3._id, original: ORIGINAL })).toBe(`/editor/ai-scenario/${ORIGINAL}`)
      expect(editUrl({ _id: 'new1' })).toBe('/editor/ai-scenario/new1')
      expect(editUrl(v3, '0.3')).toBe('/editor/ai-scenario/fabricator-training?version=0.3')
    })
  })
})
