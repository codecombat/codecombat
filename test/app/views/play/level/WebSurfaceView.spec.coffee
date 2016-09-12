WebSurfaceView = require 'views/play/level/WebSurfaceView'

describe 'WebSurfaceView', ->
  view = new WebSurfaceView({ goalManager: undefined })
  view.iframeLoaded = true
  view.iframe = {contentWindow: {postMessage: ->}}
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

  describe 'onHTMLUpdated', ->
    it 'extracts a list of all CSS selectors used', ->
      view.onHTMLUpdated({ html: studentHtml })
      expect(view.cssSelectors).toEqual(['#some-id', '.thing1, .thing2', 'div', '.element[with="attributes"]', 'p', 'div'])
