<template>
  <div>
    <div class="announcements flex-column">
      <div class="title">
        {{ $t('announcement.announcement') }}
      </div>
      <div class="content flex-column">
        <announcement-tab v-for="ann in announcements" :key="ann._id" :announcement="ann" @click.native="read(ann)"></announcement-tab>

        <div class="expand" v-if="moreAnnouncements" @click="more">expand>></div>
      </div>
    </div>
  </div>
</template>

<script>
  import fetchJson from '../../core/api/fetch-json'
  import AnnouncementModal from './announcementModal'
  import AnnouncementTab from './announcementTab'

  import { mapActions, mapGetters } from 'vuex'
  export default {
    name: 'AnnouncementView',
    computed: {
      ...mapGetters('announcements', [
        'announcements',
        'moreAnnouncements'
      ])
    },
    mounted () {
      this.getAnnouncements()
      this.lastFetch = new Date()
    },
    data () {
      return {
        lastFetch: false
      }
    },
    methods: {
      ...mapActions('announcements', [
        'openAnnouncementModal',
        'getAnnouncements',
        'readAnnouncement'
      ]),
      read (ann) {
        this.openAnnouncementModal(ann)
        if(!ann.read)
          this.readAnnouncement(ann._id)
      },
      more () {
        console.log(this.lastFetch, 'fetch')
        let startDate = new Date(this.lastFetch)
        startDate.setMonth(startDate.getMonth() - 1);
        let options = {
          append: true,
          endDate: this.lastFetch.toISOString(),
          startDate: startDate.toISOString()
        }
        this.getAnnouncements(options)
        this.lastFetch = startDate;

      }
    },
    components: {
      AnnouncementModal,
      AnnouncementTab,
    }
  }
</script>

<style scoped>
  .flex-column {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .title {
    font-size: 40px;
    font-family: bold;
    margin: 40px;
  }
  .content {
    width: 100%;
  }
</style>