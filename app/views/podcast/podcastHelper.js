const marked = require('marked')

function fullFileUrl (relativePath) {
  return `${window.location.protocol}//${window.location.host}/file/${relativePath}`
}

function podcastLinkRenderer () {
  // https://github.com/markedjs/marked/issues/655#issuecomment-383226346
  const renderer = new marked.Renderer();
  const linkRenderer = renderer.link;
  renderer.link = (href, title, text) => {
    const localLink = href.startsWith(`${location.protocol}//${location.hostname}`);
    const html = linkRenderer.call(renderer, href, title, text);
    return localLink ? html : html.replace(/^<a /, `<a target="_blank" rel="noreferrer noopener nofollow" `);
  }
  return renderer
}

module.exports = {
  fullFileUrl,
  podcastLinkRenderer
}
