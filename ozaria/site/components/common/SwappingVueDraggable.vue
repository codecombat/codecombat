<script>
  import VueDraggable from 'vuedraggable'
  import { Sortable, Swap } from 'sortablejs/modular/sortable.core.esm'

  Sortable.mount(new Swap())

  /**
   * This is a hack to allow vuedraggable to support element swapping.  SortableJS, the
   * library that drives Vue Draggable will support swap as of 1.10.0 (a release
   * candidate currently exists for it at the time of this writing.
   *
   * It works by loading a newer version of Sortable in place of the _sortable
   * objected used in VueDraggable.
   *
   * TODO when this is released, update VueDraggable version and use the built in swapping.  Remove this component.,
   */
  export default {
    extends: VueDraggable,

    mounted () {
      if (this._sortable) {
        this._sortable.destroy()
      }

      this._sortable = new Sortable(
        this.rootContainer,
        {
          ...this.options,
          swap: true
        }
      )

      this.computeIndexes()
    }
  }
</script>
