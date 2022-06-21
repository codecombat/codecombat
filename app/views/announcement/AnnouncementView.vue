<template>
  <div>
    <div class="title">
      {{ $t('announcement.announcement') }}
    </div>
    <div class="content">
      <announcement-tab v-for="ann in announcements" :key="ann._id" :announcement="ann" @click.native="openAnnouncementModal(ann)"></announcement-tab>
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
      ]),
    },
    components: {
      AnnouncementModal,
      AnnouncementTab,
    }
  }
</script>

<style>
</style>