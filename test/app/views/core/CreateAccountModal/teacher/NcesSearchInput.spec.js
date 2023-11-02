NcesSearchInput = require('views/core/CreateAccountModal/teacher/NcesSearchInput')

describe 'NcesSearchInput', ->
  it '(demo)', ->
    component = new NcesSearchInput({
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
    }).$mount()
    jasmine.demoEl(component.$el)
