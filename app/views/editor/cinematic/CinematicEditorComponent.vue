<template>
  <div>
    <h1>Some editor magic here</h1>
    <div id="treema-editor" ref="treemaEditor" v-once></div>
  </div>
</template>

<script>
import { get, put, create } from 'core/api/cinematic'
import Cinematic from 'app/models/Cinematic'

require('lib/setupTreema')

// window.Cinematic = Cinematic
// window.get = get
// window.put = put
// window.post = create

module.exports = Vue.extend({
  data: () => ({
    cinematic: null
  }),
  async mounted () {
    const c = this.cinematic = new Cinematic(await get('example1'))

    const data = $.extend(true, {}, c.attributes)
    const el = $(`<div></div>`);
    const treema = TreemaNode.make(el, {
      data: data,
      schema: Cinematic.schema
    })
    treema.build()
    $(this.$refs.treemaEditor).append(el)
    console.log(this.cinematic)
  }
})
</script>

<style>

</style>
