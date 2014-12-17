module.exports = [
  {
    id: "Introduction"
    channel: "god:new-world-created"
    noteChain: [
      name: "Set camera, start music."
      surface:
        focus:
          bounds: [{x: 0, y: 0}, {x: 80, y: 68}]
          target: "Hero Placeholder"
          zoom: 2
      sound:
        music:
          file: "/music/music_level_2"
          play: true
      script:
        duration: 1
    ]
  }
]
