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

  describe('a route marked redirectAiDisabled', () => {
    let role
    beforeEach(() => { role = me.get('role') })
    afterEach(() => {
      me.unset('aiDisabled')
      me.set('role', role)
    })

    it('sends a student or a teacher with AI off home before the Vue router moves', () => {
      for (const userRole of ['student', 'teacher']) {
        me.set({ aiDisabled: true, role: userRole })
        const router = { vueRouter: { push: jasmine.createSpy('push').and.returnValue(Promise.resolve()) }, redirectHome: jasmine.createSpy('redirectHome') }
        CocoRouter.prototype.routeDirectly.call(router, 'ai/AIView', [], { redirectAiDisabled: true })
        expect(router.redirectHome).toHaveBeenCalled()
        expect(router.vueRouter.push).not.toHaveBeenCalled()
      }
    })

    it('marks the HackStack and AI Junior pages', () => {
      const routes = CocoRouter.prototype.routes
      const aiRoutes = Object.keys(routes).filter(route => /^ai($|\/|-junior)/.test(route))
      expect(aiRoutes).toEqual(jasmine.arrayContaining(['ai', 'ai/*path', 'ai-junior', 'ai-junior/scan']))
      const fake = { calls: [], routeDirectly (path, args, options) { this.calls.push(options) } }
      for (const route of aiRoutes) { routes[route].call(fake) }
      expect(fake.calls.map(options => Boolean(options?.redirectAiDisabled))).toEqual(aiRoutes.map(() => true))
    })
  })
})
