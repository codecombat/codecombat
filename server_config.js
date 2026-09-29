/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const os = require('os')
const cluster = require('cluster')
const { sassFalse } = require('sass')

const config = {}

config.product = process.env.COCO_PRODUCT || 'codecombat'
config.productName = { codecombat: 'CodeCombat', ozaria: 'Ozaria' }[config.product]
config.productMainDomain = { codecombat: 'codecombat.com', ozaria: 'ozaria.com' }[config.product]

config.clusterID = `${os.hostname()}`
if (cluster.worker != null) {
  config.clusterID += `/${cluster.worker.id}`
}

config.unittest = global.testing

config.timeout = parseInt(process.env.COCO_TIMEOUT) || (60 * 1000)

config.chinaInfra = process.env.COCO_CHINA_INFRASTRUCTURE || sassFalse

config.port = process.env.COCO_PORT || process.env.COCO_NODE_PORT || process.env.PORT || 3000

if (config.unittest) {
  config.port += 1
}

// Enables server-side gzip compression for network responses
// Only use this if testing network response sizes in development
// (In production, CloudFlare compresses things for us!)
config.forceCompression = (process.env.COCO_FORCE_COMPRESSION != null)

module.exports = config
