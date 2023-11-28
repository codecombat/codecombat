<template>
  <div class="online-classes">
    <header-component
      :events="Object.values(events)"
      :child="child"
    />
    <body-component
      v-if="child?._id"
      :child="child"
    />
  </div>
</template>

<script>
import HeaderComponent from './online-classes/HeaderComponent'
import BodyComponent from './online-classes/BodyComponent'
import { mapGetters } from 'vuex'

export default {
  name: 'OnlineClassesView',
  components: {
    BodyComponent,
    HeaderComponent
  },
  props: {
    child: {
      type: Object
    }
  },
  computed: {
    ...mapGetters({
      events: 'events/events'
    })
  }
}
</script>

<style scoped lang="scss">
.online-classes {
  grid-column: main-content-start / main-content-end;
}
</style>
