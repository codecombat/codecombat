<template>
  <modal
    :title="$t('teacher.test_student_modal_header')"
    :backbone-dismiss-modal="true"
    @close="$emit('close')"
  >
    <div id="test-student-modal">
      <div class="modal-body">
        <p> {{ $t('teacher.test_student_modal_p1') }}</p>
        <template v-if="classLoading">
          <p>{{ $t('common.loading') }}</p>
        </template>
        <template v-else>
          <template v-if="classrooms.length">
            <span class="bold-span">{{ $t('teacher.test_student_modal_choose_class') }}</span>
            <select v-model="classCode">
              <option
                v-for="classroom in classrooms"
                :key="classroom.code"
                :value="classroom.code"
              >
                {{ classroom.name }}
              </option>
            </select>
          </template>
          <template v-else>
            <p>{{ $t('teacher.test_student_modal_no_class') }}</p>
          </template>
        </template>
        <p class="small-p">
          {{ $t('teacher.stop_spying_student') }}
        </p>
      </div>
      <div
        v-if="classCode"
        class="modal-footer"
      >
        <button
          class="dusk-btn"
          @click="joinClassroom"
        >
          {{ $t('common.continue') }}
        </button>
        <p class="small-font">
          {{ $t('teacher.test_student_modal_redirect') }}
        </p>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal.vue'
import Api from 'app/core/api/classrooms'

export default Vue.extend({
  name: 'TestStudentModal',
  components: {
    Modal,
  },
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      classrooms: [],
      classCode: '',
      classLoading: false
    }
  },
  created () {
    this.classLoading = true
    Api.fetchByOwner(me.id, { project: ['code', 'name', 'ownerID'] })
      .then(data => {
        this.classLoading = false
        this.classrooms = data
        this.classCode = data?.[0].code
      })
  },

  methods: {
    joinClassroom () {
      const text = $.i18n.t('teachers.switch_to_test_student')
      window.noty({ text, type: 'success', timeout: 5000, killer: true })
      me.spy({ id: this.id }).then(() => {
        application.router.navigate(`/courses?_cc=${this.classCode}`, { trigger: true })
      })
    }
  }
})

</script>
<style scoped lang="scss">
@import "ozaria/site/styles/common/variables.scss";
@import "ozaria/site/components/teacher-dashboard/common/_dusk-button";

#test-student-modal {
  font-size: 20px;
  padding: 20px;

  .small-p {
    font-size: 16px;
    margin-top: 5px;
  }

  .small-font {
    font-size: 14px;
    margin-top: 5px;
  }

  .bold-span {
    font-weight: bold;
  }

  .dusk-btn {
    display: inline-block;
  }
}
</style>