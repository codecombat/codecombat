
<script>
  import { mapActions } from "vuex";

  export default {
    props: {
      name: {
        type: String,
        required: true,
        default: ''
      },
      email: {
        type: String,
        required: true,
        default: ''
      },
      licensesUsed: {
        type: Number,
        required: true,
        default: 0
      },
      prepaid: {
        type: Object,
        default: () => {},
        required: true
      }
    },

    data: () => ({
      revoking: false
    }),

    computed: {
      isOwner () {
        return this.email === me.get('email');
      }
    },

    methods: {
      ...mapActions({
        revokeJoiner: 'prepaids/revokeJoiner'
      }),
      async revokeTeacher() {
        this.revoking = true;
        await this.revokeJoiner({ prepaidId: this.prepaid._id, email: this.email });
        this.revoking = false;
      }
    }
  }
</script>

<template>
  <div class="shared-pool-row">
    <div class="teacher-info">
      <span class="name"> {{ name }} {{ isOwner ?  $t('share_licenses.you') : "" }} </span>
      <a
        class="email"
        :href="'mailto:'+email"
      > {{ email }} </a>
    </div>
    <span class="licenses-used"> {{ $t("share_licenses.licenses_used_no_braces", { licensesUsed: licensesUsed }) }} </span>
    <button :disabled="isOwner || revoking" class="btn btn-danger" type="button" @click.once="revokeTeacher"> {{$t("editor.delete")}} </button>

  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.shared-pool-row {
  background: #F2F2F2;
  border-radius: 8px;
  height: 71px;
  width: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  padding: 10px 20px;
}

.teacher-info {
  display: flex;
  flex-direction: column;
}

.name {
  @include font-p-2-paragraph-medium-gray;
  font-weight: 600;
  color: $pitch;
}

.email {
  @include font-p-3-paragraph-small-blue-link;
}

.licenses-used {
  font-family: Work Sans;
  font-style: normal;
  font-weight: 600;
  font-size: 14px;
  line-height: 18px;
  letter-spacing: 0.4px;
  text-transform: uppercase;
  color: $pitch;
}
</style>
