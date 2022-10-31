export default {
  methods: {
    getMinLicenses (price) {
      return price.metadata.minLicenses ? parseInt(price.metadata.minLicenses) : null
    },

    getLicenseCap (price) {
      return price.metadata.licenseCap ? parseInt(price.metadata.licenseCap) : null
    }
  }
}
