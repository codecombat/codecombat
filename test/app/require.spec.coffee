describe 'require', ->
  it 'has no modules that error when you import them', ->
    modules = window.require.list()
    for module in modules
      try
        require(module)
      catch
        console.error 'Could not load', module
        expect(false).toBe(true)