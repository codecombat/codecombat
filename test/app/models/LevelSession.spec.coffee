LevelSession = require('models/LevelSession')
VCS = require('lib/VCS')

describe 'LevelSession', ->
  describe 'VCS', ->
    it 'lets me insert a revision and sets the previoius revision correctly', ->
      levelSession = new LevelSession()
      levelSession.set 'code', "TestCode"
      levelSession.set 'code', "TestCode2"
      expect(levelSession.getWorkingRevision().previous.getCode()).toBe("TestCode")

    it 'should return the same code for a revision after insertion of new revisions', ->
      levelSession = new LevelSession()
      testCode1 = "TestCode1"
      levelSession.set 'code', testCode1
      levelSession.set 'code', "TestCode2"
      levelSession.set 'code', "TestCode3"
      expect(levelSession.getWorkingRevision().previous.previous.getCode()).toBe(testCode1)

    it 'should return the same code for a revision after insertion of a new branch', ->
      levelSession = new LevelSession()
      testCode1 = "TestCode1"
      levelSession.set 'code', testCode1
      levelSession.set 'code', "TestCode2"
      levelSession.loadRevision levelSession.getWorkingRevision().previous
      levelSession.set 'code', "TestCode3"
      expect(levelSession.getWorkingRevision().previous.getCode()).toBe(testCode1)

    it 'should create a second head if a new branch is created', ->
      levelSession = new LevelSession()
      testCode1 = "TestCode1"
      levelSession.set 'code', testCode1
      levelSession.set 'code', "TestCode2"
      levelSession.loadRevision levelSession.getWorkingRevision().previous
      levelSession.set 'code', "TestCode3"
      expect(levelSession.getHeadRevisions().length).toBe(2)

    it 'should serialize and deserialize', ->
      ls = new LevelSession()
      testCode1 = "TestCode1"
      ls.set 'code', testCode1
      ls.set 'code', "TestCode2"
      ls.loadRevision ls.getWorkingRevision().previous
      ls.set 'code', "TestCode3"
      vcs2 = new VCS null, ls.get 'vcs'
      expect(vcs2.heads.length).toBe(ls.getHeadRevisions().length)

    it 'should prune old revisions if more than 100(?)', ->
      levelSession = new LevelSession()
      i = 0
      while i < 123
        console.log "[TEST] Inserting new CodeNode: TestCode" + i
        levelSession.set 'code', "TestCode" + i++
      expect(levelSession.getRevisions().length).toBe(100)