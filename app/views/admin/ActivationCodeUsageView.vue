<template>
  <div>
    <div class="title">
      Activation Code Usage Look Up
    </div>
    <div class="body">
      <div class="search">
        <input
          v-model="code"
          type="text"
          placeholder="Input the code"
        >
        <input
          type="button"
          value="submit"
          @click="submit"
        >
      </div>
      <div class="prepaid-table">
        <div class="summary row">
          {{ summary }}
        </div>
        <div class="code-row bold">
          <div class="code">
            Code
          </div>
          <div class="user">
            User
          </div>
          <div class="used">
            Used
          </div>
        </div>
        <div
          v-for="line in sortedCodes"
          :key="`line-${line.code}`"
          class="code-row"
        >
          <div class="code">
            {{ mapCode(line.code) }}
          </div>
          <div class="user">
            {{ line.userID }}
          </div>
          <div class="used">
            {{ line.userID ? 'Yes' : 'No' }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api from 'app/core/api'
export default {
  name: 'ActivationCodeUsage',
  data () {
    return {
      code: '',
      prepaid: {},
      codeType: 'normal',
    }
  },
  computed: {
    summary () {
      const maxRedeemers = this.prepaid.maxRedeemers || 0
      const used = this.prepaid.redeemers?.filter(r => r.userID)?.length || 0
      let summary = `This prepaid can redeem ${maxRedeemers} users, now used ${used}.`
      if (this.codeType !== 'normal') {
        let expire = 'expired'
        if (new Date(this.prepaid.endDate) > new Date()) {
          expire = 'will expire'
        }
        summary += `This prepaid ${expire} at ${this.prepaid.endDate}`
      }
      return summary
    },
    sortedCodes () {
      if (this.code.length === 8) {
        return []
      }
      if (!this.prepaid.redeemers) {
        return []
      }
      let matchCode = this.code.slice(4, 8)
      if (this.codeType === 'teacher') {
        matchCode = this.code.slice(7, 11)
      } else if (this.codeType === 'student') {
        matchCode = this.code.slice(5, 9)
      }
      const codes = this.prepaid.redeemers
      codes.sort((a, b) => {
        const getPriority = (item) => {
          if (item.code === matchCode) return 2 // Exact match
          if (item.userID) return 1 // Has a user
          return 0 // Default
        }
        return getPriority(b) - getPriority(a)
      })
      return codes
    },
  },
  watch: {
    code (newVal) {
      if (newVal.length === 8) {
        this.codeType = 'normal'
      } else if (newVal.length === 12) {
        this.codeType = 'home'
      } else if (newVal[0] === 'T') {
        this.codeType = 'teacher'
      } else if (newVal.split('-').length === 3) {
        this.codeType = 'student'
      } else {
        this.codeType = 'normal'
      }
    },
  },
  mounted () {
    if (!me.isAdmin()) {
      window.location.href = '/'
    }
  },
  methods: {
    async submit () {
      if (!this.code) { return }
      this.prepaid = await api.prepaids.detailsByCodes(this.code.toLowerCase())
    },
    mapCode (code) {
      const pCode = this.prepaid.code
      const part1 = pCode.slice(0, 4)
      const part2 = pCode.slice(4)
      if (this.codeType === 'teacher') {
        return `T-${part1}-${code}-${part2}`.toUpperCase()
      } else if (this.codeType === 'student') {
        return `${part1}-${code}-${part2}`.toUpperCase()
      } else if (this.codeType === 'home') {
        return `${part1}${code}${part2}`.toUpperCase()
      }
      return ''
    },
  },
}
</script>
<style scoped lang="scss">
.title {
  margin-top: 60px;
  text-align: center;
  font-size: 42px;
  font-weight: 800;
}
.body {
  margin: 40px;
  padding: 60px;

  .prepaid-table {
    .code-row {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;

      &.bold {
        font-weight: 800;
      }
      .code, .user, .used {
      }
    }
  }
}
</style>