<template lang="pug">
#announcement-modal-base-flat.modal
  .modal-dialog.style-flat
    .modal-header
      .button.close(type='button' data-dismiss="modal" aria-hidden="true") &times;
      h3.title {{name}}
    block content
     .markdown(v-html="content")
     a.see-more.btn.btn-primary(v-if="showMoreAnnouncementButton && unread", @click="$emit('close')" href='/announcements' ) {{$t('announcement.see_more', {unread})}}
</template>

<script>
import DOMPurify from 'dompurify';
import { mapGetters } from 'vuex'
import utils from 'core/utils'

export default Vue.extend({
    name: 'announcement-modal',
    props: ['announcement'],
    computed: {
      ...mapGetters('announcements', [
        'showMoreAnnouncementButton',
        'unread'
      ]),
      name () {
        return utils.i18n(this.announcement, 'name')
      },
      content (){
        let i18nContent = utils.i18n(this.announcement, 'content')
        return DOMPurify.sanitize(marked(i18nContent || ''))
      }
    }
})
</script>

<styple lang="sass" scoped>
  #announcement-modal-base-flat
    position: absolute
    width: 100%

    .modal-dialog
      margin: 60px auto 0 auto
      padding: 25px
      min-width: 746px
      min-height: 520px
      background: white
      box-shadow: 0 3px 9px rgba(0, 0, 0, 0.5)

    .modal-content
      box-shadow: none
      height: 520px

      .markdown
        position: absolute
        top: 120px
        padding: 0 50px


    .see-more
      position: absolute
      bottom: 10px
    //- Background
    #subscribe-background
      position: absolute
      top: -61px
      left: 0px

    //- Header
    h1
      position: absolute
      left: 170px
      top: 25px
      margin: 0
      width: 410px
      text-align: center
      color: rgb(254,188,68)
      font-size: 38px
      text-shadow: black 4px 4px 0, black -4px -4px 0, black 4px -4px 0, black -4px 4px 0, black 4px 0px 0, black 0px -4px 0, black -4px 0px 0, black 0px 4px 0, black 6px 6px 6px
      font-variant: normal
      text-transform: uppercase


    //- Close modal button
    #close-modal
      position: absolute
      left: 568px
      top: 17px
      width: 60px
      height: 60px
      color: white
      text-align: center
      font-size: 30px
      padding-top: 15px
      cursor: pointer

      &:hover
        color: yellow
</styple>
