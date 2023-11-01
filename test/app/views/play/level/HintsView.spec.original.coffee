HintsView = require 'views/play/level/HintsView'
factories = require 'test/app/factories'

hintWithCode = """
Hint #2 rosebud

```python
print('Hello World')
```

```javascript
console.log('Hello World')
```
"""

longHint = _.times(100, -> 'Beuller...').join('\n\n')

xdescribe 'HintsView', ->
  beforeEach ->
    level = factories.makeLevel({
      documentation: {
        hints: [
          { body: 'Hint #1 xyzzy' }
          { body: hintWithCode }
          { body: longHint }
        ]
      }
    })
    @session = factories.makeLevelSession({ playtime: 0 })
    @view = new HintsView({ level, @session })
    @view.render()
    jasmine.demoEl(@view.$el)
    
  describe 'when the first hint is shown', ->
    
    it 'does not show the previous button', ->
      expect(@view.$el.find('.previous-btn').length).toBe(0)

  describe 'when the user has played for a while', ->

    beforeEach ->
      @view.render()

    it 'shows the first hint', ->
      expect(_.string.contains(@view.$el.text(), 'xyzzy')).toBe(true)

    it 'shows the next hint button', ->
      expect(@view.$el.find('.next-btn').length).toBe(1)

  it 'filters out all code blocks but those of the selected language', ->
    @session.set({
      codeLanguage: 'javascript'
      playtime: 9001
    })
    @view.state.set('hintIndex', 1)
    @view.render()
    
    if _.string.contains(@view.$el.text(), 'print')
      fail('Python code snippet found, should be filtered out')
    if not _.string.contains(@view.$el.text(), 'console')
      fail('JavaScript code snippet not found')
