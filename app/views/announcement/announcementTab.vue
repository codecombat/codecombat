<template>
  <div
    class="tab"
    :class="{read: announcement.read, truncated: isEllipsisActive}"
  >
    <div class="left">
      <div class="time">
        {{ time }}
      </div>
    </div>
    <div class="right">
      <div class="title">
        {{ name }}
      </div>
      <div
        :id="`content${announcement._id}`"
        class="content"
        :class="{truncated: isEllipsisActive}"
        v-html="content"
      />
      <div
        class="read-more"
        @click="readfull(announcement._id)"
      >
        <p>read more</p>
      </div>
    </div>
    <div
      class="readit"
      @click="read(announcement._id)"
    >
      {{ $t('announcement.mark_read') }}
    </div>
  </div>
</template>

<script>
import DOMPurify from 'dompurify'
import utils from 'core/utils'
import moment from 'moment'

import { mapActions } from 'vuex'
export default {
  name: 'AnnouncementTab',
  props: ['announcement', 'scrolledTo'],
  data () {
    return {
      display: false,
      isEllipsisActive: false
    }
  },
  computed: {
    name () {
      return utils.i18n(this.announcement, 'name')
    },
    content () {
      const i18nContent = utils.i18n(this.announcement, 'content')
      return DOMPurify.sanitize(window.marked(i18nContent || ''))
    },
    time () {
      return moment(this.announcement.startDate).format('ll')
    }
  },
  mounted () {
    const el = document.querySelector(`#content${this.announcement._id}`)
    this.isEllipsisActive = this.checkEllipsisActive(el)

    if (this.scrolledTo) {
      el.classList.add('force-all')
      // top level component
      el.parentElement.parentElement.scrollIntoView({ behaviors: 'smooth', block: 'center' })
    }

  },
  methods: {
    ...mapActions('announcements', [
      'readAnnouncement'
    ]),
    read (id) {
      if (!this.announcement.read) {
        this.readAnnouncement(id)
      }
    },
    readfull (id) {
      const el = document.querySelector(`#content${id}`)
      el.classList.add('force-all')
    },
    // checkEllipsisActive and checkRange coming from
    // https://stackoverflow.com/a/64747288
    // which checks if the text truncated by css
    // so don't need to review logic, it works good!
    checkEllipsisActive (el) {
      return el.scrollHeight !== el.offsetHeight
        ? el.scrollHeight > el.offsetHeight
        : this.checkRanges(el)
    },
    checkRanges (el) {
      const range = new Range()
      range.selectNodeContents(el)
      const rangeRect = range.getBoundingClientRect()
      const elRect = el.getBoundingClientRect()
      if (rangeRect.bottom > elRect.bottom) {
        return true
      }
      el.classList.add('text-overflow-ellipsis')
      const rectsEllipsis = range.getClientRects()
      el.classList.add('text-overflow-clip')
      const rectsClipped = range.getClientRects()
      el.classList.remove('text-overflow-ellipsis')
      el.classList.remove('text-overflow-clip')
      return rectsClipped.length !== rectsEllipsis.length
    }
  }
}
</script>

<style scoped lang="scss">

.tab {
  width: 80%;
  min-height: 60px;
  display: flex;
  position: relative;
  margin: 2em;

  padding-bottom: 4em;
  border-bottom: 1px solid #1fbab4;

  .readit {
    display: none;
    position: absolute;
    right: 20px;
    bottom: 20px;
    padding: 5px 15px;
    border: 1px solid black;
    border-radius: 5px;
    font-weight: 600;
    cursor: pointer;
  }

  &:not(.read, .truncated):hover .readit {
    display: block;
  }

  .left {
    flex-basis: 20%;
    flex-shrink: 0;
  }
  .right {
    max-width: 80%;
    flex-grow: 0;
    position: relative;
  }

  &.read {
    opacity: 50%;
  }

    .title {
      font-size: 24px;
      font-weight: bold;
      position: relative;
    }

    .content{
      margin-top: 15px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow-y: hidden;
      text-overflow: ellipsis;
      overflow-wrap: break-word;
      max-width: 100%;

      &.text-overflow-ellipsis {
        text-overflow: ellipsis !important;
      }
      &.text-overflow-clip{
        text-overflow: clip !important;
      }

      &.truncated ~ .read-more{
        display: block
      }

      &.force-all {
        display: block !important;
      }
      &.force-all ~ .read-more {
        display: none !important;
      }
    }
  .read-more {
    display: none;
    position: absolute;
    cursor: pointer;
    bottom: -4em;
    width: 100%;
    z-index: 5;
    padding-top: 4em;
    background-image: linear-gradient(to top, #fff 60%, rgba(255, 255, 255, 0.1) 100%);

    p {
      color: #333;
      text-align: center;
      font-size: 16px;
      font-weight: 600;
    }
  }
}

</style>