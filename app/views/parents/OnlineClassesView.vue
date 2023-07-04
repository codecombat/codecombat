<template>
  <div class="online-classes">
    <header-component />
    <body-component
      v-if="child?._id"
      :child="child"
    />
  </div>
</template>

<script>
import HeaderComponent from './online-classes/HeaderComponent'
import BodyComponent from './online-classes/BodyComponent'

export default {
  name: 'OnlineClassesView',
  props: {
    child: {
      type: Object
    }
  },
  components: {
    BodyComponent,
    HeaderComponent
  }
}
</script>

<style scoped lang="scss">
.online-classes {
  grid-column: main-content-start / main-content-end;
}
</style>
