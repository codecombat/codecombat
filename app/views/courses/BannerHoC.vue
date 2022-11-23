<script>
import utils from 'core/utils'
export default Vue.extend({
  data () {
    return {
      show: false,
      when: new Date('2022-12-01 14:00 PST')
    }
  },
  created () {
    this.show = new Date() < new Date(this.when.getTime() + 60 * 60 * 1000)
    this.whenDisplay = moment(this.when).calendar(null, { sameElse: 'ddd MMM D, LT' })

    const host = utils.isCodeCombat ? '' : 'https://codecombat.com'
    this.url = `${host}/teachers/hour-of-code`
  }
})
</script>

<template>
  <div
      id="banner-hoc"
      v-if="show"
      class="container"
  >
    <div class="row">
      <div class="col-xs-12">
        <div id="announcement">
          <p>
            Join us {{ whenDisplay }} for our Hour of Code Walkthrough! Everything you need to implement our all new
            activities
            <a :href="url" target="_blank">
              HERE.
            </a>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/utils";

#banner-hoc {

@if $is-ozaria {
  #announcement {
    background-color: #cff2fc;
    border-radius: 10px;
    padding: 20px;
    margin: 20px 80px 20px 80px;
    text-align: center;
  }
}

  @if $is-codecombat {

    #announcement {
      background-color: #0097A7;
      border: 3px solid #595959;
      border-radius: 20px;

      p {
        color: white;
      }

      a {
        color: white;
        text-decoration: underline;
        font-weight: bold;
      }
    }
  }

  #announcement {
    margin-right: 80px;
    margin-left: 80px;
    p {
      margin: 14px;
      font-size: 18px;
      line-height: 29px;
      text-align: center;
    }
  }

  &.container {
    .row {
      padding: 0 !important
    }
  }
}
</style>
