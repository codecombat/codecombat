describe 'Router', ->
  Router = require 'lib/Router'
  it 'caches the home view', ->
    router = new Router()
    router.openRoute('home')
    expect(router.cache['home']).toBe(router.currentView)
    home = router.currentView
    router.openRoute('home')
    expect(router.cache['home']).toBe(router.currentView)
