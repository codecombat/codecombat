const AuthView = require('views/account/AuthView')

describe('AuthView', function () {
  let view

  beforeEach(function () {
    jasmine.clock().install()
  })

  afterEach(function () {
    jasmine.clock().uninstall()
    if (view) {
      view.destroy()
      view = null
    }
    window.history.replaceState({}, '', '/')
  })

  function renderAt (path) {
    window.history.replaceState({}, '', path)
    view = new AuthView()
    view.render()
    jasmine.demoEl(view.$el)
    return view
  }

  it('renders signup chooser at /signup', function () {
    renderAt('/signup')

    expect(view.getMode()).toBe('signup')
    expect(view.$('.auth-path-button').length).toBe(4)
    expect(view.$('.auth-login-form').length).toBe(0)
  })

  it('renders login form at /login', function () {
    renderAt('/login')

    expect(view.getMode()).toBe('login')
    expect(view.$('.auth-login-form').length).toBe(1)
    expect(view.$('.auth-path-button').length).toBe(0)
  })

  it('toggles from signup to login in-page', function () {
    renderAt('/signup')
    jasmine.spyOn(application.router, 'navigate')

    view.$('.auth-mode-link').click()

    expect(application.router.navigate).toHaveBeenCalledWith('/login', { trigger: true })
  })

  it('routes chooser cards to current destinations', function () {
    renderAt('/signup')
    jasmine.spyOn(application.router, 'navigate')

    view.$('.teacher-path-button').click()
    expect(application.router.navigate).toHaveBeenCalledWith('/teachers/signup', { trigger: true })

    application.router.navigate.calls.reset()
    view.$('.student-path-button').click()
    expect(application.router.navigate).toHaveBeenCalledWith('/students', { trigger: true })

    application.router.navigate.calls.reset()
    view.$('.individual-path-button').click()
    expect(application.router.navigate).toHaveBeenCalledWith('/signup?type=individual', { trigger: true })
  })
})
