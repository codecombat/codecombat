module.exports = class DialogueAnimator
  jqueryElement: null
  childrenToAdd: null
  charsToAdd: null
  childAnimator: null

  constructor: (html, @jqueryElement) ->
    d = $('<div></div>').html(html)
    @childrenToAdd = _.map(d[0].childNodes, (e) -> return e)

  tick: ->
    if not @charsToAdd and not @childAnimator
      @addNextElement()

    if @charsToAdd
      @addSingleChar()
      return

    if @childAnimator
      @childAnimator.tick()
      if @childAnimator.done()
        @childAnimator = null

  addNextElement: ->
    return unless @childrenToAdd.length
    nextElem = @childrenToAdd[0]
    @childrenToAdd = @childrenToAdd[1..]
    if nextElem.nodeName is '#text'
      @charsToAdd = _.string.chars(nextElem.nodeValue)
    else
      value = nextElem.innerHTML
      newElem = $(nextElem).html('')
      @jqueryElement.append(newElem)
      if value
        @childAnimator = new DialogueAnimator(value, newElem)

  addSingleChar: ->
    @jqueryElement.html(@jqueryElement.html() + @charsToAdd[0])
    @charsToAdd = @charsToAdd[1..]
    if @charsToAdd.length is 0
      @charsToAdd = null

  done: ->
    return false if @childrenToAdd.length > 0
    return false if @charsToAdd
    return false if @childAnimator
    return true
