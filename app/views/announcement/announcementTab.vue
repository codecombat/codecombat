<template>
  <div class="tab" :class="{read: announcement.read}">
    <div class="title">
      {{name}}
    </div>
  </div>
</template>

<script>
  import utils from 'core/utils'
  export default {
    name: 'announcement-tab',
    props: ['announcement'],
    computed: {
      name () {
        return utils.i18n(this.announcement, 'name')
      }
    }

  }
</script>

<style scoped>

  .tab {
    width: 60%;
    height: 60px;
    border: 1px solid black;
    border-radius: 20px;
    margin: 15px;
  }

  .tab.read {
    background-color: #aaabbb;
    background-blend-mode: multiply;
  }

  .title {
    font-size: 24px;
    line-height: 60px;
    text-align: center;
  }

</style>