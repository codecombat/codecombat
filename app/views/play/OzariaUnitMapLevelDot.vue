<template lang="pug">
  div.level-dot(:style="levelDotStyle", :class="levelDotClass")
    a.level-dot-link(:href="getPlayLevelLink")
</template>

<script>
  import { mapGetters } from 'vuex'

  export default {
    props: {
      levelData: {
        type: Object,
        required: true
      },

      courseId: {
        type: String
      },

      courseInstanceId: {
        type: String
      }
    },

    computed: {
      ...mapGetters('game', [
        'isLevelUnlocked',
        'isLevelNext'
      ]),

      levelLocked () {
        return !this.isLevelUnlocked(this.level.original)
      },

      levelNext () {
        return this.isLevelNext(this.level.original)
      },

      // red - unlocked levels; yellow - next level (also unlocked); grey - locked level
      // TODO: update CSS after UI specs
      levelDotStyle: function () {

        let position = {
          left: this.levelData.position.x + '%',
          bottom: this.levelData.position.y + '%'
        }

        if (this.levelLocked) {
          return _.extend({}, position, {
            'background-color': 'grey'
          })
        } else if (this.levelNext) {
          return _.extend({}, position, {
            'background-color': 'yellow'
          })
        } else {
          return _.extend({}, position, {
            'background-color': 'rgb(255, 80, 60)' // this.levelData.color
          })
        }
      },

      levelDotClass: function () {
        return {
          locked: this.levelLocked,
          next: this.levelNext
        }
      },

      getPlayLevelLink: function () {
        let link = ''
        if (this.levelLocked) {
          return '#'
        }

        if (this.courseId && this.courseInstanceId) {
          // TODO encode uri component
          link = '/play/level/' +
            this.levelData.slug +
            '?course=' + this.courseId +
            '&course-instance=' + this.courseInstanceId

          if (this.levelData.primerLanguage) {
            link += '&codeLanguage=' + this.levelData.primerLanguage
          }
        } else {
          link = '/play/level/' + this.levelData.slug
        }

        return link || '#'
      }
    }
  }
</script>

<style lang="sass">
  .level-dot
    position: absolute
    width: 1.5%
    height: 2%
    border: 2px groove white
    border-radius: 50%

  .level-dot-link
    width: 100%
    height: 100%
    position: absolute
</style>


