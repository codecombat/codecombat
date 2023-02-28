<template lang="pug">
modal(@close="$emit('close')")
  .modal-body
    .title {{name}}
    .content(v-html="content")
    a.see-more.btn.btn-primary(v-if="showMoreAnnouncementButton && (true || unread)", @click="$emit('close')" href='/announcements' ) {{$t('announcement.see_more', {unread})}}
</template>

<script>
import { mapGetters } from 'vuex'
import Modal from '../../components/common/Modal'
import utils from 'core/utils'
import DOMPurify from 'dompurify'

export default Vue.extend({
  name: 'AnnouncementModal',
  components: {
    Modal
  },
  props: ['announcement'],
  computed: {
    ...mapGetters('announcements', [
      'showMoreAnnouncementButton',
      'announcementModalOpen',
      'unread'
    ]),
    name () {
      return utils.i18n(this.announcement, 'name')
    },
    content () {
      const i18nContent = utils.i18n(this.announcement, 'content')
      return DOMPurify.sanitize(window.marked(i18nContent || ''))
    }
  },
  watch: {
    announcementModalOpen (val) {
      $('#announcement-modal-base-flat').modal(val ? 'show' : 'hide')
    }
  }
})
</script>

<style lang="sass" scoped>
 .modal-body
   min-width: 746px
   min-height: 520px
   background: linear-gradient(0deg, #fdffff -1.56%, #D7EFF2 45%,  #D7EFF2 55%, #FDFFFF 95.05%)
   display: flex
   flex-direction: column
   align-items: center

 .title
   font-size: 24px
   font-weight: bold
   position: relative

 .content
   margin-top: 15px

 .see-more
   position: absolute
   bottom: 10px
</style>
