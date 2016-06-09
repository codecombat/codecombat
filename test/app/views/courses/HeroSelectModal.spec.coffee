HeroSelectModal = require 'views/courses/HeroSelectModal'
factories = require 'test/app/factories'

describe 'HeroSelectModal', ->

  modal = null
  coursesView = null
  user = null

  hero1 = factories.makeThangType({ original: "hero1original", _id: "hero1id", heroClass: "Warrior", name: "Hero 1" })
  hero2 = factories.makeThangType({ original: "hero2original", _id: "hero2id", heroClass: "Warrior", name: "Hero 2" })
  heroesResponse = JSON.stringify([hero1, hero2])

  beforeEach (done) ->
    window.me = user = factories.makeUser({ heroConfig: { thangType: hero1.get('original') } })
    modal = new HeroSelectModal({ currentHeroID: hero1.id })
    modal.heroes.fakeRequests[0].respondWith({ status: 200, responseText: heroesResponse })
    jasmine.demoModal(modal)
    _.defer ->
      modal.render()
      done()

  afterEach ->
    modal.stopListening()

  it 'highlights the current hero', ->
    expect(modal.$(".hero-option[data-hero-id='#{hero1.id}']")[0].className.split(" ")).toContain('selected')

  it 'saves when you change heroes', (done) ->
    modal.$(".hero-option[data-hero-id='#{hero2.id}']").click()
    _.defer ->
      expect(user.fakeRequests.length).toBe(1)
      request = user.fakeRequests[0]
      expect(request.method).toBe("PUT")
      expect(JSON.parse(request.params).heroConfig?.thangType).toBe(hero2.get('original'))
      done()
