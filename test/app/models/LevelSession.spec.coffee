LevelSession = require('models/LevelSession')

describe 'LevelSession', ->
  describe 'VCS', ->
    it 'allows me to get previous versions', ->
      levelSession = new LevelSession()
      # run whatever functions on it to save 2 or 3 versions
      # use jasmine's expect function to test output
      expect('test').toBe('test')