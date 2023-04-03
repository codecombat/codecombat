<template>
  <main class="content">
    <campaign-list-component
      :campaigns="campaigns"
    />
    <campaign-basic-summary />
    <campaign-progress-view
      :campaign="campaigns[0]"
    />
  </main>
</template>

<script>
import CampaignListComponent from './main-content/CampaignListComponent'
import CampaignBasicSummary from './main-content/CampaignBasicSummary'
import CampaignProgressView from './main-content/CampaignProgressView'

export default {
  name: 'MainContentComponent',
  components: {
    CampaignListComponent,
    CampaignBasicSummary,
    CampaignProgressView
  },
  data () {
    return {
      campaigns: [
        { id: 1, name: 'Kithgard Dungeon',
          levels: [
            {
              id: 1,
              name: 'Dungeon level 1',
              description: 'description of dungeon level 1 is...',
              type: 'cutscene'
            },
            {
              id: 2,
              name: 'Dungeon level 2',
              description: 'description of dungeon level 2 is...',
              type: 'cutscene'
            },
            {
              id: 3,
              name: 'Dungeon level 3',
              description: 'description of dungeon level 3 is...',
              type: 'cinematic'
            },
            {
              id: 4,
              name: 'Dungeon level 4',
              description: 'description of dungeon level 4 is...',
              type: 'cutscene'
            },
            {
              id: 5,
              name: 'Abc Dungeon level 5',
              description: 'description of dungeon level 5 is...',
              type: 'capstone'
            }
          ]
        },
        { id: 2, name: 'Game dev 1' },
        { id: 3, name: 'Web dev 1' },
        { id: 4, name: 'Backwoods forest' },
        { id: 5, name: 'Web dev 2' }
      ]
    }
  }
}
</script>

<style scoped lang="scss">
.content {
  grid-column: main-content-start / main-content-end;
  /*height: 60vh;*/
}
</style>
