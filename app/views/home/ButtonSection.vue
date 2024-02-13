<template>
  <div>
    <div
      v-if="me.isAnonymous()"
      class="button-section"
    >
      <CTAButton
        class="signup-button"
        :data-start-on-path="utils.isCodeCombat ? 'oz-vs-coco' : 'teacher'"
        @click="homePageEvent(isCodeCombat? 'Homepage Click Teacher Button #1 CTA' : 'Started Signup')"
      >
        {{ $t('new_home.im_an_educator') }}
      </CTAButton>
      <CTAButton
        href="/parents/signup"
        @click="homePageEvent('Homepage Click Parent Button CTA')"
      >
        {{ $t('new_home.im_a_parent') }}
      </CTAButton>
      <CTAButton
        class="signup-button"
        data-start-on-path="student"
        @click="homePageEvent('Started Signup');homePageEvent('Homepage Click Student Button CTA')"
      >
        {{ $t('new_home.im_a_student') }}
      </CTAButton>
    </div>
    <div
      v-else
      class="button-section"
    >
      <CTAButton
        v-if="me.isTeacher()"
        href="/teachers/classes"
        @click="homePageEvent('Homepage Click My Classes CTA')"
      >
        {{ $t('new_home.go_to_my_classes') }}
      </CTAButton>
      <CTAButton
        v-else-if="me.isStudent()"
        href="/students"
        @click="homePageEvent('Homepage Click My Courses CTA')"
      >
        {{ $t('new_home.go_to_courses') }}
      </CTAButton>
      <CTAButton
        v-else
        href="/play"
        @click="homePageEvent('Homepage Click Continue Playing CTA')"
      >
        {{ $t('courses.continue_playing') }}
      </CTAButton>
    </div>
  </div>
</template>

<script>
import CTAButton from '../../components/common/buttons/CTAButton'
import utils from 'core/utils'

export default {
  name: 'ButtonSection',
  components: {
    CTAButton
  },
  data () {
    return {
      modal: null
    }
  },
  computed: {
    utils () {
      return utils
    },
    me () {
      return me
    }
  },
  beforeDestroy () {
    if (this.modal) {
      this.modal.remove()
    }
  },
  methods: {
    homePageEvent (action) {
      action = action || 'unknown'
      const properties = {
        category: utils.isCodeCombat ? 'Homepage' : 'Home',
        user: me.get('role') || (me.isAnonymous() && 'anonymous') || 'homeuser'
      }
      return (window.tracker != null ? window.tracker.trackEvent(action, properties) : undefined)
    }
  }
}

</script>

<style scoped lang="scss">
    .button-section {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      gap: 12px;
      margin-top: 40px;
      margin-bottom: 40px;
    }
</style>
