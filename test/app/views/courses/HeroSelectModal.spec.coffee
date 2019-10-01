HeroSelectModal = require 'views/courses/HeroSelectModal'
factories = require 'test/app/factories'
api = require 'core/api'

describe 'HeroSelectModal', ->

  modal = null
  coursesView = null
  user = null

  hero1 = factories.makeThangType({ original: "hero1original", _id: "hero1id", heroClass: "Warrior", name: "Hero 1" })
  hero2 = factories.makeThangType({ original: "hero2original", _id: "hero2id", heroClass: "Warrior", name: "Hero 2" })
  heroesResponse = JSON.stringify([hero1, hero2])

  beforeEach (done) ->
    window.me = user = factories.makeUser({ heroConfig: { thangType: hero1.get('original') } })
    heroesPromise = Promise.resolve([hero1.attributes, hero2.attributes])
    spyOn(api.thangTypes, 'getHeroes').and.returnValue(heroesPromise)
    modal = new HeroSelectModal()
    subview = modal.subviews.hero_select_view
    jasmine.demoModal(modal)
    heroesPromise.then ->
      _.defer ->
        modal.render()
        done()

  afterEach ->
    modal.stopListening()

  it 'highlights the current hero', ->
    expect(modal.$(".hero-option[data-hero-original='#{hero1.get('original')}']")?[0]?.className.split(" ")).toContain('selected')

  it 'saves when you change heroes', (done) ->
    modal.$(".hero-option[data-hero-original='#{hero2.get('original')}']").click()
    setTimeout -> # TODO Webpack: Figure out how to not need this race condition
      expect(user.fakeRequests.length).toBe(1)
      request = user.fakeRequests[0]
      expect(request?.method).toBe("PUT")
      expect(JSON.parse(request?.params).heroConfig?.thangType).toBe(hero2.get('original'))
      done()
    , 500

  it 'triggers its events properly', (done) ->
    spyOn(modal, 'trigger')
    modal.render()
    modal.$('.hero-option:nth-child(2)').click()
    request = jasmine.Ajax.requests.mostRecent()
    request.respondWith({ status: 200, responseText: me.attributes })
    expect(modal.trigger).toHaveBeenCalled()
    expect(modal.trigger.calls.argsFor(0)[0]).toBe('hero-select:success')
    expect(modal.trigger).not.toHaveBeenCalledWith('hide')
    modal.$('.select-hero-btn').click()
    expect(modal.trigger).toHaveBeenCalledWith('hide')
    done()
