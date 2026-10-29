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
})
