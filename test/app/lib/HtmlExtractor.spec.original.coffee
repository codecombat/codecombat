HtmlExtractor = require 'lib/HtmlExtractor'

# TODO: Fix these in Travis; something's wrong with how htmlparser2/deku load.
xdescribe 'HtmlExtractor', ->
  studentHtml = """
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
    </div>
  """
  describe 'extractCssSelectors', ->
    it 'extracts a list of all CSS selectors used in CSS code or jQuery calls', ->
      { styles, scripts } = HtmlExtractor.extractStylesAndScripts(studentHtml)
      extractedSelectors = HtmlExtractor.extractCssSelectors(styles, scripts)
      expect(extractedSelectors).toEqual(['#some-id', '.thing1, .thing2', 'div', '.element[with="attributes"]', 'p', 'div'])

    it 'extracts a list of all CSS selectors used in CSS code', ->
      { styles, scripts } = HtmlExtractor.extractStylesAndScripts(studentHtml)
      extractedSelectors = HtmlExtractor.extractSelectorsFromCss(styles, scripts)
      expect(extractedSelectors).toEqual(['#some-id', '.thing1, .thing2', 'div', '.element[with="attributes"]'])

    it 'extracts a list of all CSS selectors used in jQuery calls', ->
      { styles, scripts } = HtmlExtractor.extractStylesAndScripts(studentHtml)
      extractedSelectors = HtmlExtractor.extractSelectorsFromJS(scripts)
      expect(extractedSelectors).toEqual(['p', 'div'])
