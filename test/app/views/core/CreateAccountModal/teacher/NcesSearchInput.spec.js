/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const NcesSearchInput = require('views/core/CreateAccountModal/teacher/NcesSearchInput');

describe('NcesSearchInput', () => it('(demo)', function() {
  const component = new NcesSearchInput({
    data: {
      suggestions: [
        {
          _highlightResult: {
            name: { value: 'School' },
            district: { value: 'District' },
            city: { value: 'City' },
            state: { value: 'State' }
          }
        }
      ]
    }
  }).$mount();
  return jasmine.demoEl(component.$el);
}));
