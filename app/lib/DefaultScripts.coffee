module.exports = [
  {
    channel: "god:new-world-created"
    noteChain: []
    id: "Introduction"
  }
  {
    channel: "world:won"
    noteChain: []
    id: "Victory Playback"
    scriptPrereqs: ["Introduction"]
  }
  {
    channel: "level-set-playing"
    noteChain: []
    scriptPrereqs: ["Victory Playback"]
    id: "Victory Playback Started"
  }
  {
    channel: "surface:frame-changed"
    noteChain: []
    scriptPrereqs: ["Victory Playback Started"]
    id: "Show Victory"
  }
]