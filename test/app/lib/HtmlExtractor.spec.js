/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const HtmlExtractor = require('lib/HtmlExtractor');

// TODO: Fix these in Travis; something's wrong with how htmlparser2/deku load.
xdescribe('HtmlExtractor', function() {
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
  return describe('extractCssSelectors', function() {
    it('extracts a list of all CSS selectors used in CSS code or jQuery calls', function() {
      const { styles, scripts } = HtmlExtractor.extractStylesAndScripts(studentHtml);
      const extractedSelectors = HtmlExtractor.extractCssSelectors(styles, scripts);
      return expect(extractedSelectors).toEqual(['#some-id', '.thing1, .thing2', 'div', '.element[with="attributes"]', 'p', 'div']);
    });

    it('extracts a list of all CSS selectors used in CSS code', function() {
      const { styles, scripts } = HtmlExtractor.extractStylesAndScripts(studentHtml);
      const extractedSelectors = HtmlExtractor.extractSelectorsFromCss(styles, scripts);
      return expect(extractedSelectors).toEqual(['#some-id', '.thing1, .thing2', 'div', '.element[with="attributes"]']);
    });

    return it('extracts a list of all CSS selectors used in jQuery calls', function() {
      const { styles, scripts } = HtmlExtractor.extractStylesAndScripts(studentHtml);
      const extractedSelectors = HtmlExtractor.extractSelectorsFromJS(scripts);
      return expect(extractedSelectors).toEqual(['p', 'div']);
    });
  });
});
