LevelSessions = require 'collections/LevelSessions';

module.exports = new LevelSessions(
  [
    # student0 - 4/4
    {
      level:
        original: "level0_0",
      creator: "student0",
      state:
        "complete": true
    },
    {
      level:
        original: "level0_1",
      creator: "student0",
      state:
        "complete": true
    },
    {
      level:
        original: "level0_2",
      creator: "student0",
      state:
        "complete": true
    },
    {
      level:
        original: "level0_3",
      creator: "student0",
      state:
        "complete": true
    },
    
    # student1 - 2.5/4
    {
      level:
        original: "level0_0",
      creator: "student1",
      state:
        "complete": true
    },
    {
      level:
        original: "level0_1",
      creator: "student1",
      state:
        "complete": true
    },
    {
      level:
        original: "level0_2",
      creator: "student1",
      state:
        "complete": false
    },
    
    # student2 - 0.5/4
    {
      level:
        original: "level0_0",
      creator: "student2",
      state:
        "complete": false
    },
    
    # student3 - 0/4
  ]
)
