/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const WebSurfaceView = require('views/play/level/WebSurfaceView');

describe('WebSurfaceView', function() {
  const view = new WebSurfaceView({ goalManager: undefined });
  view.iframeLoaded = true;
  view.iframe = {contentWindow: {postMessage() {}}};
  const studentHtml = `\
<style>
  #some-id {}
  .thing1, .thing2 {
    color: blue;
  }
  div { something: invalid }
  .element[with="attributes"] {}
</style>
<script>
  var paragraphs = $(  \t"p" )
  paragraphs.toggleClass("some-class")
  $('div').children().insertAfter($('<a> '))
</script>
<div>
  Hi there!
</div>\
`;

  return describe('onHTMLUpdated', () => it('extracts a list of all CSS selectors used', function() {
    view.onHTMLUpdated({ html: studentHtml });
    return expect(view.cssSelectors).toEqual(['#some-id', '.thing1, .thing2', 'div', '.element[with="attributes"]', 'p', 'div']);
  }));
});
