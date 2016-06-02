HeroSelectModal = require 'views/courses/HeroSelectModal'
auth = require 'core/auth'
factories = require 'test/app/factories'

describe 'HeroSelectModal', ->

  modal = null
  coursesView = null
  user = null

  heroesResponse = """[{"_id":"56d75b87ce1bec240007b0d0","heroClass":"Ranger","name":"Assassin","original":"566a2202e132c81f00f38c81"},{"_id":"56b5d150eba6d22400e78bdc","name":"Captain","original":"529ec584c423d4e83b000014","heroClass":"Warrior"},{"_id":"56b4ddfe6eeec15800a182be","heroClass":"Ranger","name":"Forest Archer","original":"5466d4f2417c8b48a9811e87"},{"_id":"56b4e9451d894e290043cf20","heroClass":"Warrior","name":"Goliath","original":"55e1a6e876cb0948c96af9f8"},{"_id":"56f02d49fd900f24002eaa47","heroClass":"Warrior","name":"Guardian","original":"566a058620de41290036a745"},{"_id":"56b4df48e4c1d74b00878e92","name":"Knight","original":"529ffbf1cf1818f2be000001","heroClass":"Warrior"},{"_id":"56ce1207a8b61e481ab3bddd","name":"Librarian","original":"52fbf74b7e01835453bd8d8e","heroClass":"Wizard"},{"_id":"57113e91f45cd02300cbe9fa","heroClass":"Wizard","name":"Necromancer","original":"55652fb3b9effa46a1f775fd"},{"_id":"56f02e1da978161f00839e7d","name":"Ninja","original":"52fc0ed77e01835453bd8f6c","heroClass":"Ranger"},{"_id":"56b4eda9a4df6b1f0060a546","name":"Potion Master","original":"52e9adf7427172ae56002172","heroClass":"Wizard"},{"_id":"56f030ad4832405700790731","heroClass":"Warrior","name":"Raider","original":"55527eb0b8abf4ba1fe9a107"},{"_id":"56b4fcc0eba6d22400e76de4","name":"Samurai","original":"53e12be0d042f23505c3023b","heroClass":"Warrior"},{"_id":"56c2318ccd6205471aa71fe5","name":"Sorcerer","original":"52fd1524c7e6cf99160e7bc9","heroClass":"Wizard"},{"_id":"56b5041c56d79e24003d4815","heroClass":"Ranger","name":"Trapper","original":"5466d449417c8b48a9811e83"}]"""
  anyaID = "56b5d150eba6d22400e78bdc"
  anyaOriginal = "529ec584c423d4e83b000014"
  illiaID = "56f02d49fd900f24002eaa47"
  illiaOriginal = "566a058620de41290036a745"

  beforeEach (done) ->
    window.me = user = factories.makeUser({ heroConfig: { thangType: anyaOriginal } })
    auth.loginUser(user.attributes)
    modal = new HeroSelectModal({ currentHeroID: anyaID })
    modal.heroes.fakeRequests[0].respondWith({ status: 200, responseText: heroesResponse })
    jasmine.demoModal(modal)
    _.defer ->
      modal.render()
      done()

  afterEach ->
    modal.stopListening()

  it 'highlights the current hero', ->
    expect(modal.$(".hero-option[data-hero-id='#{anyaID}']")[0].className.split(" ")).toContain('selected')

  it 'saves when you change heroes', (done) ->
    modal.$(".hero-option[data-hero-id='#{illiaID}']").click()
    _.defer ->
      expect(user.fakeRequests.length).toBe(1)
      request = user.fakeRequests[0]
      expect(request.method).toBe("PUT")
      expect(JSON.parse(request.params).heroConfig?.thangType).toBe(illiaOriginal)
      done()
