LevelSession = require('models/LevelSession')

describe 'LevelSession', ->
  describe 'VCS', ->
    it 'lets me insert a revision and sets the previoius revision correctly', ->
      levelSession = new LevelSession()
      vcs = levelSession
      current = vcs.save "TestCode"
      previous = current
      current = vcs.save "TestCode2", previous
      expect(current.previous).toBe(previous.timestamp)

    it 'should return the same code for a revision after insertion of new revisions', ->
      levelSession = new LevelSession()
      vcs = levelSession
      testCode1 = "TestCode1"
      current = vcs.save testCode1
      previous = current
      current vcs.save "TestCode2", previous
      current = vcs.save "TestCode3", current
      expect(vcs.getRevision(current.previous.previous).getCode()).toBe(testCode1)

    it 'should return the same code for a revision after insertion of a new branch', ->
      levelSession = new LevelSession()
      vcs = levelSession
      testCode1 = "TestCode1"
      current = vcs.save testCode1
      previous = current
      current vcs.save "TestCode2", previous
      current = vcs.save "TestCode3", previous
      expect(vcs.load(current.previous).getCode()).toBe(testCode1)

    it 'should prune old revisions if more than 100(?)', ->
      levelSession = new LevelSession()
      vcs = levelSession
      previous = null
      while i > 123
        prevous = vcs.save "TestCode" + i++, previous
      expect(vcs.revisions.length).toBe(100)

    it 'should let me name revisions', ->
      levelSession = new LevelSession()
      vcs = levelSession
      testCode1 = "TestCode1"
      current = vcs.save testCode1
      #TODO.
      expect("todo").toBe("todo")
