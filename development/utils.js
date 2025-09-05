const product = process.env.COCO_PRODUCT || 'codecombat'
const productSuffix = { codecombat: 'coco', ozaria: 'ozar' }[product]
const publicFolderName = 'public_' + productSuffix
const isStaging = process.env.COCO_IS_STAGING_SERVER

module.exports = {
  product,
  productSuffix,
  publicFolderName,
  isStaging,
}
