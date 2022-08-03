<template>
  <div
    class="tab"
    :class="{read: announcement.read, collapsed: !display}"
  >
    <div
      class="title"
      :data-toggle="alwaysDisplay ? '': 'collapse'"
      :data-target="'#collapse-' + announcement._id"
      :class="{clickable: !alwaysDisplay}"
      @click="toggleDisplay"
    >
      {{name}}
    </div>
    <div
      :id="'collapse-' + announcement._id"
      class="content collapse"
    >
      {{ content }}
    </div>
  </div>
</template>

<script>
import utils from 'core/utils'
export default {
  name: 'AnnouncementTab',
  props: ['announcement', 'alwaysDisplay'],
  data () {
    return {
      display: false
    }
  },
  computed: {
    name () {
      return utils.i18n(this.announcement, 'name')
    },
    content () {
      return utils.i18n(this.announcement, 'content')
    }
  },
  mounted () {
    if (this.alwaysDisplay) {
      this.display = true
    }
  },
  methods: {
    toggleDisplay () {
      if (this.alwaysDisplay) {
        return
      }
      this.display = !this.display
    }
  }
}
</script>

<style scoped lang="scss">

.tab {
  width: 50%;
  min-height: 60px;
  border: 2px solid #1FBAB4;
  border-radius: 10px;
  cursor: pointer;
  margin: 15px;
  tansition: height 1s;

  &.read {
    background-color: #ddd;
    background-blend-mode: multiply;
  }

  &.collapsed{

    &> .title:before {
      content: '+';
    }
  }

  .title {
    padding-left: 2em;
    padding-right: 2em;
    font-size: 24px;
    line-height: 60px;
    text-align: center;
    position: relative;

    &.clickable {
      cursor: pointer;
    }

    &:before {
      content: '-';
      position: absolute;
      font-weight: 800;
      border: 2px solid #1fbab4;
      color: #1fbab4;
      border-radius: 50%;
      width: 30px;
      height: 30px;
      line-height: 26px;
      text-align: center;
      left: 10px;
      top: 15px;

    }

  }

  .content {
    border-left: 15px solid transparent;
    border-right: 15px solid transparent;
    border-top: 1px solid #1fbab4;
    margin: 15px;
    padding: 15px;
  }
}

</style>