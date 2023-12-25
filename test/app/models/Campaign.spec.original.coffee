Campaign = require 'models/Campaign'

describe 'Campaign', ->
  
  getLevelData = {
    '1234': { campaignIndex: 1, slug: 'second' },
    '5678': { campaignIndex: 0, slug: 'first' }
  }
  
  describe 'getLevels', ->
    it 'returns a list of levels sorted by campaignIndex', ->
      campaign = new Campaign({ levels:getLevelData })
      levels = campaign.getLevels()
      expect(levels.toJSON()).toEqual([getLevelData['5678'], getLevelData['1234']])

  describe '@getLevels', ->
    it 'takes a campaign object and returns a list of levels sorted by campaignIndex', ->
      levels = Campaign.getLevels({ levels: getLevelData })
      expect(levels).toEqual([getLevelData['5678'], getLevelData['1234']])

      
  getLevelNumberData = {
    '0': { original: 'a', campaignIndex: 0, slug: 'first', name: 'First' },
    '1': { original: 'b', campaignIndex: 1, slug: 'second', name: 'Second' }
    '2': { original: 'c', campaignIndex: 2, slug: 'second practice', name: 'Second A', practice: true }
    '3': { original: 'd', campaignIndex: 3, slug: 'second practice', name: 'Second B', practice: true }
    '4': { original: 'e', campaignIndex: 4, slug: 'third', name: 'Third' }
  }
      
  describe 'getLevelNumber', ->
    it 'returns the level number taking into account practice levels', ->
      campaign = new Campaign({ levels: getLevelNumberData })
      expect(campaign.getLevelNumber('a')).toBe(1)
      expect(campaign.getLevelNumber('b')).toBe(2)
      expect(campaign.getLevelNumber('c')).toBe('2a')
      expect(campaign.getLevelNumber('d')).toBe('2b')
      expect(campaign.getLevelNumber('e')).toBe(3)

  describe '@getLevelNumberMap', ->
    it 'takes a campaign and returns an object mapping level original to level "number"', ->
      levelMap = Campaign.getLevelNumberMap({ levels: getLevelNumberData })
      expect(levelMap).toEqual({a: 1, b: 2, c: "2a", d: "2b", e: 3})
