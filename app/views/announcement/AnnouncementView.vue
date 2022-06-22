<template>
  <div>
    <div class="announcements flex-column">
      <div class="title">
        {{ $t('announcement.announcement') }}
      </div>
      <div class="content flex-column">
        <announcement-tab v-for="ann in announcements" :key="ann._id" :announcement="ann" @click.native="read(ann)"></announcement-tab>
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
        'announcements'
      ])
    },
    mounted () {
      this.getAnnouncements()
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

  .content {
    width: 100%;
  }
</style>