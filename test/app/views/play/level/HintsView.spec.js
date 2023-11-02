/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const HintsView = require('views/play/level/HintsView');
const factories = require('test/app/factories');

const hintWithCode = `\
Hint #2 rosebud

\`\`\`python
print('Hello World')
\`\`\`

\`\`\`javascript
console.log('Hello World')
\`\`\`\
`;

const longHint = _.times(100, () => 'Beuller...').join('\n\n');

xdescribe('HintsView', function() {
  beforeEach(function() {
    const level = factories.makeLevel({
      documentation: {
        hints: [
          { body: 'Hint #1 xyzzy' },
          { body: hintWithCode },
          { body: longHint }
        ]
      }
    });
    this.session = factories.makeLevelSession({ playtime: 0 });
    this.view = new HintsView({ level, session: this.session });
    this.view.render();
    return jasmine.demoEl(this.view.$el);
  });
    
  describe('when the first hint is shown', () => it('does not show the previous button', function() {
    return expect(this.view.$el.find('.previous-btn').length).toBe(0);
  }));

  describe('when the user has played for a while', function() {

    beforeEach(function() {
      return this.view.render();
    });

    it('shows the first hint', function() {
      return expect(_.string.contains(this.view.$el.text(), 'xyzzy')).toBe(true);
    });

    return it('shows the next hint button', function() {
      return expect(this.view.$el.find('.next-btn').length).toBe(1);
    });
  });

  return it('filters out all code blocks but those of the selected language', function() {
    this.session.set({
      codeLanguage: 'javascript',
      playtime: 9001
    });
    this.view.state.set('hintIndex', 1);
    this.view.render();
    
    if (_.string.contains(this.view.$el.text(), 'print')) {
      fail('Python code snippet found, should be filtered out');
    }
    if (!_.string.contains(this.view.$el.text(), 'console')) {
      return fail('JavaScript code snippet not found');
    }
  });
});
