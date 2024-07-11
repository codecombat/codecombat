<template>
  <div id="test-student-modal">
    <span
      class="glyphicon glyphicon-remove button close"
      data-dismiss="modal"
    />
    <h3 class="modal-header text-center">
      {{ $t('teacher.test_student_modal_header') }}
    </h3>
    <div class="modal-body">
      <!-- todo: i18n and styles -->
      <p> {{ $t('teacher.test_student_modal_p1') }}</p>

      <p>{{ $t('teacher.test_student_modal_choose_class') }}</p>
      <select v-model="classCode">
        <option
          v-for="classroom in classrooms"
          :key="classroom.code"
          :value="classroom.code"
        >
          {{ classroom.name }}
        </option>
      </select>
    </div>
    <div class="modal-footer">
      <p>{{ $t('teacher.test_student_modal_redirect') }}</p>
      <button @click="JoinClassroom">
        {{ $t('code.continue') }}
      </button>
    </div>
  </div>
</template>

<script>
const fetchJson = require('../../../core/api/fetch-json')
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
    fetchJson(`/db/classroom?ownerID=${me.id}&project=code,name,ownerID`)
      .then(data => {
        this.classrooms = data
        this.classCode = data[0].code
      })
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
<style scoped lang="scss">
#test-student-modal {
  background: white;
  box-shadow: 0 3px 9px rgb(0 0 0 / 50%);
  font-size: 20px;

  border-radius: 15px;
  padding: 20px;
}
</style>