import seasonalLeague from '../../../core/store/modules/seasonalLeague'

export default {
  beforeCreate () {
    if (!this.$store.hasModule('seasonalLeague')) {
      this.$store.registerModule('seasonalLeague', seasonalLeague)
    }
  }
}
