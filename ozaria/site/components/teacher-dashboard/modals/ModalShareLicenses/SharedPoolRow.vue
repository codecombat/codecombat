
<script>
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
      }
    },

    computed: {
      nameWithSuffix () {
        if (this.email === me.get('email')) {
          return this.name + ' ' + this.$t('share_licenses.you')
        } else {
          return this.name
        }
      }
    }
  }
</script>

<template>
  <div class="shared-pool-row">
    <div class="teacher-info">
      <span class="name"> {{ nameWithSuffix }} </span>
      <a
        class="email"
        :href="'mailto:'+email"
      > {{ email }} </a>
    </div>
    <span class="licenses-used"> {{ $t("share_licenses.licenses_used_no_braces", { licensesUsed: licensesUsed }) }} </span>
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
