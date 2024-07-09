<template>
  <div>
    <!-- todo: i18n and styles -->
    <p>You'll be creating a unique test account that mimics the student journey and saves your progress.</p>

    <p>Choose a class to join:</p>
    <select v-model="classCode">
      <option
        v-for="classroom in classrooms"
        :key="classroom.code"
        :value="classroom.code"
      >
        {{ classroom.name }}
      </option>
    </select>

    You will be redirected to your test student account!
    <button @click="JoinClassroom">
      Continue
    </button>
  </div>
</template>

<script>
/* const fetchJson = require('../../../core/api/fetch-json') */
export default Vue.extend({
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      classrooms: [],
      classCode: ''
    }
  },
  created () {
    // todo: show class loading...
    /* fetchJson(`/db/classroom?ownerID=${me.id}&project=code,name`)
     *   .then(data => (this.classrooms = data)) */
  },

  methods: {
    JoinClassroom () {
      me.spy({ id: this.id }).then(() => {
        application.router.navigate(`/courses?_cc=${this.classCode}`, { trigger: true })
      })
    }
  }
})

</script>