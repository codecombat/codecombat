function fullFileUrl (relativePath) {
  return `${window.location.protocol}//${window.location.host}/file/${relativePath}`
}

module.exports = {
  fullFileUrl
}
