<template lang="pug">
  div.level-dot(:style="levelDotStyle", :class="levelDotClass")
    a.level-dot-link(:href="getPlayLevelLink")
</template>

<script>
export default Vue.extend({
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
    // red - unlocked levels; yellow - next level (also unlocked); grey - locked level
    // TODO: update CSS after UI specs
    levelDotStyle: function() {
      let position = {
        left: this.levelData.position.x + '%',
        bottom: this.levelData.position.y + "%",
      }
      if (this.levelData.locked) {
        return _.extend({}, position, {
          'background-color': 'grey'
        })
      } else if (this.levelData.next) {
        return _.extend({}, position, {
          'background-color': 'yellow'
        })
      } else {
        return _.extend({}, position, {
          'background-color': 'rgb(255, 80, 60)' //this.levelData.color
        })
      }
    },
    levelDotClass: function() {
      return {
        locked: this.levelData.locked,
        next: this.levelData.next
      }
    },
    getPlayLevelLink: function() {
      let link = ''
      if (this.levelData.locked)
        return '#'

      if (this.levelData.type == 'intro') {
        link = '/ozaria/play/intro/' + this.levelData.slug
      } else {
        link = '/ozaria/play/level/' + this.levelData.slug
      }

      if (this.courseId && this.courseInstanceId) {
        link += "?course=" + this.courseId + "&course-instance=" + this.courseInstanceId
        if (this.levelData.primerLanguage)
          link += "&codeLanguage=" + this.levelData.primerLanguage 
      }
      return link || '#'
    }
  }
})
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


