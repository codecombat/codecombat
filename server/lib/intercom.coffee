config = require '../../server_config'
Intercom = require('intercom-client')
module.exports = new Intercom.Client({ token: config.intercom.accessToken }) # 'test' in base64
