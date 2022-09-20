const product = process.env.COCO_PRODUCT || 'codecombat'
const productSuffix = { codecombat: 'coco', ozaria: 'ozar' }[product]
const publicFolderName = 'public_' + productSuffix

module.exports = {
  product,
  productSuffix,
  publicFolderName
}
