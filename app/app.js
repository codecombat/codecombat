global.$ = window.$ = global.jQuery = window.jQuery = require('jquery');
import 'bootstrap'
import './app.sass'

require('app/vendor.js')

// require.context('app/schemas', true, /.*\.(coffee|jade)/)
// require.context('app/models', true, /.*\.(coffee|jade)/)
// require.context('app/collections', true, /.*\.(coffee|jade)/)
// require.context('app/core', true, /.*\.(coffee|jade)/)
// require.context('app/views/core', true, /.*\.(coffee|jade)/)

require('core/initialize');
