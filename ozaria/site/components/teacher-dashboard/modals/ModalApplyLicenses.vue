<script>
  import Modal from '../../common/Modal'
  import SecondaryButton from '../common/buttons/SecondaryButton'

  export default Vue.extend({
    components: {
      Modal,
      SecondaryButton
    },
    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: 'Teachers' })
        }
      }
    }
  })
</script>

<template>
  <modal
    :title="$t('teacher.apply_licenses')"
    @close="$emit('close')"
  >
    <div class="apply-licenses">
      <div class="apply-licenses-info">
        <span class="sub-title"> {{$t('teacher.apply_modal_subtitle')}} </span>
        <ul class="info-list">
          <li class="list-item"> {{$t('teacher.apply_modal_list_item_1')}} </li>
          <li class="list-item"> {{$t('teacher.apply_modal_list_item_2')}} </li>
          <li class="list-item"> {{$t('teacher.apply_modal_list_item_3')}} </li>
        </ul>
      </div>
      <div class="apply-licenses-img">
        <img src="/images/ozaria/teachers/dashboard/my_licenses/apply_licenses.png">
      </div>
      <div class="buttons">
        <router-link
          tag="a"
          to="/teachers/classes"
        >
          <secondary-button
            @click.native="trackEvent('My Licenses: Go to My Classes Clicked from Apply Licenses Modal')"
          >
            {{ $t("new_home.go_to_my_classes") }}
          </secondary-button>
        </router-link>
      </div>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "ozaria/site/styles/common/variables.scss";

.apply-licenses {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 20px;
  width: 600px;
}

.sub-title {
  @include font-p-2-paragraph-medium-gray;
  font-weight: 600;
  color: $pitch;
}

.info-list {
  margin: 15px -20px;
}

.list-item {
  @include font-p-3-paragraph-small-gray;
  margin: 5px 0px;
}

.apply-licenses-img {
  margin-bottom: 70px;
  margin-top: 30px;
  width: 535px;
  height: 210px;
  img {
    width: 100%;
  }
}

.buttons {
  align-self: flex-end;
  display: flex;
  margin-top: 30px;

  button {
    width: 200px;
    height: 35px;
    margin: 0 10px;
  }
}

</style>
