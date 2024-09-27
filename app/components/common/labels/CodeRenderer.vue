<script>
export default {
  props: {
    content: {
      type: String,
      required: true,
    },
  },
  render (h) {
    return h('span', { domProps: { innerHTML: this.content.replace(/`(.*?)`/g, '<code>$1</code>') } })
  },
}
</script>