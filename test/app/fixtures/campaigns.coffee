Campaign = require 'models/Campaign'
Campaigns = require 'collections/Campaigns'

module.exports = new Campaigns([
  new Campaign({
    _id: 'campaign0'
    levels: [
      {
        _id: 'level0_0'
        original: 'level0_0'
        name: 'level0_0'
        type: 'hero'
      },
      {
        _id: 'level0_1'
        original: 'level0_1'
        name: 'level0_1'
        type: 'hero'
      },
      {
        _id: 'level0_2'
        original: 'level0_2'
        name: 'level0_2'
        type: 'hero'
      },
      {
        _id: 'level0_3'
        original: 'level0_3'
        name: 'level0_3'
        type: 'hero'
      },
    ]
  }),
])
