<template>
  <ul class="dropdown-menu announcement-menu">
    <li
      v-for="a in announcements"
      :key="a._id"
      class="title"
      :class="{read: a.read}"
      @click="read(a._id)"
    >
      {{ naming(a) }}
    </li>
    <template v-if="moreAnnouncements">
      <li class="split" />
      <li
        class="more"
        @click="more"
      >
        view more
      </li>
    </template>
  </ul>
</template>

<script>
import utils from 'core/utils'

import { mapActions, mapGetters } from 'vuex'
export default {
  name: 'AnnouncementView',
  computed: {
    ...mapGetters('announcements', [
      'announcements',
      'unread',
      'moreAnnouncements'
    ])
  },
  mounted () {
    this.getAnnouncements()
  },
  methods: {
    ...mapActions('announcements', [
      'getAnnouncements'
    ]),
    naming (announcement) {
      return utils.i18n(announcement, 'name')
    },
    read (id) {
      application.router.navigate(`/announcements?id=${id}`, { trigger: true })
    },
    more () {
      application.router.navigate(`/announcements?skip=${this.announcements.length}`, { trigger: true })
    }
  }
}
</script>

<style scoped lang="scss">
.announcement-menu {

  font-size: 18px;
  font-weight: 500;
  line-height: 25px;

  .title {
    overflow: hidden;
    text-overflow: ellipsis;
    margin: 10px;
    margin-left: 15px;
    margin-right: 15px;
    text-align: left;
    cursor: pointer;
  }

  .read {
    opacity: 50%;
  }

  li.split {
    margin: 15px;
    border-top: 1px solid #aaa;
  }

  li.more {
    margin: 10px;
    margin-bottom: 15px;
    cursor: pointer;
    color: #333;
  }
}
</style>
