<template>
  <h1>Hello Cinematic editor view</h1>
</template>

<script>
import { get, put, create } from 'core/api/cinematic'
import Cinematic from 'app/models/Cinematic'

window.Cinematic = Cinematic
window.get = get
window.put = put
window.post = create
module.exports = Vue.extend({

})
</script>

<style>

</style>
