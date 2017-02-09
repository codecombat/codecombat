User = require '../../../server/models/User'
request = require '../request'
utils = require '../utils'
geoip = require '@basicer/geoip-lite'
esper = require '../../../bower_components/esper.js/esper.modern.js'

describe 'GET /user-data', ->
  beforeEach utils.wrap ->
    yield utils.clearModels([User])

    @engine = new esper.Engine()
    @win = {
      location: {
        pathname: '/scott'
      }
    }
    @engine.addGlobalBridge 'window', @win

  it 'returns an empty user with no cookie', utils.wrap ->
    url = utils.getUrl '/user-data'
    [res, body] = yield request.getAsync url
    expect(body).toContain 'window.userObject = {};'
    expect(res.statusCode).toBe(200)
    expect(=> @engine.evalSync(body)).not.toThrow()
    expect(@engine.globalScope.get("me")).toBeDefined()


  describe 'when the user is in China', ->
    it 'contains a redirect', utils.wrap ->
      url = utils.getUrl '/user-data'
      spyOn(geoip, 'lookup').and.callFake -> 
        return {country: 'CN' }

      [res, body] = yield request.getAsync url,
        headers:
          'Accept-Language': 'zh-HANS=0.8; en-US=0.2'
      expect(body).toContain "window.location = 'https://cn.codecombat.com' + window.location.pathname;"
      expect(res.statusCode).toBe(200)

      result = @engine.evalSync(body).toNative();
      expect(@win.location == "https://cn.codecombat.com/scott")
      
