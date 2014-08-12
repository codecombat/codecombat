LevelSession = require('models/LevelSession')

describe 'LevelSession', ->
  describe 'VCS', ->
    it 'lets me insert a revision and sets the previoius revision correctly', ->
      levelSession = new LevelSession()
      # run whatever functions on it to save 2 or 3 versions
      # use jasmine's expect function to test output
      vcs = levelSession.get 'vcs'
      vcs = {revisions: []} unless vcs
      current = levelSession.saveCodeRevision "TestCode"
      previous = current
      current levelSession.saveCodeRevision "TestCode2", previous
      expect(current.previous).toBe(previous.timestamp)

    it 'should return the same code for a revision after insertion of new revisions', ->
      levelSession = new LevelSession()
      vcs = levelSession.get 'vcs'
      vcs = {revisions: []} unless vcs
      testCode1 = "TestCode1"
      current = levelSession.saveCodeRevision testCode1
      previous = current
      current levelSession.saveCodeRevision "TestCode2", previous
      current = levelSession.saveCodeRevision "TestCode3", current
      expect(levelSession.getCodeRevision(current.previous.previous).getCode()).toBe(testCode1)

    it 'should return the same code for a revision after insertion of a new branch', ->
      levelSession = new LevelSession()
      vcs = levelSession.get 'vcs'
      vcs = {revisions: []} unless vcs
      testCode1 = "TestCode1"
      current = levelSession.saveCodeRevision testCode1
      previous = current
      current levelSession.saveCodeRevision "TestCode2", previous
      current = levelSession.saveCodeRevision "TestCode3", previous
      expect(levelSession.getCodeRevision(current.previous).getCode()).toBe(testCode1)

    it 'should prune old revisions if more than 100(?)', ->
      levelSession = new LevelSession()
      vcs = levelSession.get 'vcs'
      vcs = {revisions: []} unless vcs
      previous = null
      while i > 123
        prevous = levelSession.saveCodeRevision "TestCode" + i++, previous
      expect(vcs.revisions.length).toBe(100)