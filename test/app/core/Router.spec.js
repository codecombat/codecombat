const CocoRouter = require('core/Router')
const dynamicRequire = require('lib/dynamicRequire')

describe('CocoRouter', () => {
  it('registers every view a route loads in lib/dynamicRequire', () => {
    const missing = []
    for (const [route, handler] of Object.entries(CocoRouter.prototype.routes)) {
      const path = typeof handler === 'function' ? handler.viewPath : null
      if (!path) { continue }
      const key = path.startsWith('views/') ? path : `views/${path}`
      if (typeof dynamicRequire[key] !== 'function') { missing.push(`${route || '/'} -> ${key}`) }
    }
    expect(missing).toEqual([])
  })

  it('counts a page as opened when its view is open, without waiting for its images', async (done) => {
    const router = {
      vueRouter: { push: jasmine.createSpy('push').and.returnValue(Promise.resolve()) },
      viewLoad: { setView () {}, record: () => new Promise(() => {}) },
      openView: jasmine.createSpy('openView'),
    }
    CocoRouter.prototype.routeDirectly.call(router, 'NotFoundView', [], { recursive: true })
    await router.routeLoad
    expect(router.openView).toHaveBeenCalled()
    done()
  })

  describe('a route marked redirectAiDisabled', () => {
    let role, noty
    beforeEach(() => {
      role = me.get('role')
      noty = window.noty
      window.noty = jasmine.createSpy('noty')
    })
    afterEach(() => {
      window.noty = noty
      me.unset('aiDisabled')
      me.set('role', role)
    })

    it('sends a student or a teacher with AI off home before the Vue router moves', () => {
      for (const userRole of ['student', 'teacher']) {
        me.set({ aiDisabled: true, role: userRole })
        const router = { vueRouter: { push: jasmine.createSpy('push').and.returnValue(Promise.resolve()) }, redirectHome: jasmine.createSpy('redirectHome'), routeLoad: new Promise(() => {}) }
        CocoRouter.prototype.routeDirectly.call(router, 'ai/AIView', [], { redirectAiDisabled: true })
        expect(router.redirectHome).toHaveBeenCalled()
        expect(router.vueRouter.push).not.toHaveBeenCalled()
      }
    })

    it('tells the user the page is not available, after the home page has opened', async (done) => {
      me.set({ aiDisabled: true, role: 'student' })
      let homeOpened
      const router = { vueRouter: { push: jasmine.createSpy('push') } }
      router.redirectHome = () => { router.routeLoad = new Promise(resolve => { homeOpened = resolve }) }
      const told = CocoRouter.prototype.routeDirectly.call(router, 'ai/AIView', [], { redirectAiDisabled: true })
      await Promise.resolve()
      expect(window.noty).not.toHaveBeenCalled()
      homeOpened()
      await told
      expect(window.noty).toHaveBeenCalledWith(jasmine.objectContaining({ text: "This page isn't available for your account." }))
      done()
    })

    it('lets a student with AI on through', () => {
      me.set({ aiDisabled: false, role: 'student' })
      const router = { vueRouter: { push: jasmine.createSpy('push').and.returnValue(Promise.resolve()) }, redirectHome: jasmine.createSpy('redirectHome') }
      CocoRouter.prototype.routeDirectly.call(router, 'ai/AIView', [], { redirectAiDisabled: true })
      expect(router.redirectHome).not.toHaveBeenCalled()
      expect(router.vueRouter.push).toHaveBeenCalled()
      expect(window.noty).not.toHaveBeenCalled()
    })

    it('marks the HackStack and AI Junior pages, the teacher dashboard AI Junior page included', () => {
      const routes = CocoRouter.prototype.routes
      const aiRoutes = Object.keys(routes).filter(route => /^(teachers\/)?ai($|\/|-junior)/.test(route))
      expect(aiRoutes).toEqual(jasmine.arrayContaining(['ai', 'ai/*path', 'ai-junior', 'ai-junior/scan', 'teachers/ai-junior/:classroomId']))
      const fake = { calls: [], routeDirectly (path, args, options) { this.calls.push(options) } }
      for (const route of aiRoutes) { routes[route].call(fake) }
      expect(fake.calls.map(options => Boolean(options?.redirectAiDisabled))).toEqual(aiRoutes.map(() => true))
    })
  })
})
