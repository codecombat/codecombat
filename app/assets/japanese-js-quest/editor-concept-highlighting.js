(function (root, factory) {
  const api = factory()
  if (typeof module === 'object' && module.exports) module.exports = api
  else {
    root.JSQuestConceptHighlighting = api
    api.install()
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict'

  const OBJECT_NAMES = new Set(['hero'])
  const VALUE_WORDS = new Set(['true', 'false', 'null', 'undefined', 'NaN', 'Infinity'])

  function escapeHtml (value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;')
  }

  function span (className, value) {
    return '<span class="syntax-' + className + '">' + escapeHtml(value) + '</span>'
  }

  function scanCode (source, onToken) {
    const text = String(source)
    let index = 0

    while (index < text.length) {
      const character = text[index]
      const next = text[index + 1]

      if (character === '/' && next === '/') {
        const start = index
        index += 2
        while (index < text.length && text[index] !== '\n') index++
        onToken('comment', text.slice(start, index), start, index)
        continue
      }

      if (character === '/' && next === '*') {
        const start = index
        index += 2
        while (index < text.length && !(text[index] === '*' && text[index + 1] === '/')) index++
        if (index < text.length) index += 2
        onToken('comment', text.slice(start, index), start, index)
        continue
      }

      if (character === '"' || character === "'" || character === '`') {
        const quote = character
        const start = index
        index++
        let escaped = false
        while (index < text.length) {
          const current = text[index]
          index++
          if (escaped) escaped = false
          else if (current === '\\') escaped = true
          else if (current === quote) break
        }
        onToken('string', text.slice(start, index), start, index)
        continue
      }

      if (/[A-Za-z_$]/.test(character)) {
        const start = index
        index++
        while (index < text.length && /[A-Za-z0-9_$]/.test(text[index])) index++
        onToken('word', text.slice(start, index), start, index)
        continue
      }

      if (/\d/.test(character) && (index === 0 || !/[A-Za-z0-9_$]/.test(text[index - 1]))) {
        const start = index
        index++
        while (index < text.length && /[0-9._xobA-Fa-f]/.test(text[index])) index++
        onToken('number', text.slice(start, index), start, index)
        continue
      }

      onToken('plain', character, index, index + 1)
      index++
    }
  }

  function declaredNames (source) {
    const names = new Set()
    const codeParts = []
    scanCode(source, (type, value) => {
      codeParts.push(type === 'comment' || type === 'string' ? ' '.repeat(value.length) : value)
    })
    const code = codeParts.join('')
    const pattern = /\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)/g
    for (const match of code.matchAll(pattern)) names.add(match[1])
    return names
  }

  function previousNonSpace (source, index) {
    for (let cursor = index - 1; cursor >= 0; cursor--) {
      if (!/\s/.test(source[cursor])) return source[cursor]
    }
    return ''
  }

  function nextNonSpace (source, index) {
    for (let cursor = index; cursor < source.length; cursor++) {
      if (!/\s/.test(source[cursor])) return source[cursor]
    }
    return ''
  }

  function renderString (value) {
    if (value.length < 2) return escapeHtml(value)
    const quote = value[0]
    const closed = value[value.length - 1] === quote
    const inner = value.slice(1, closed ? -1 : value.length)
    return escapeHtml(quote) + span('literal', inner) + (closed ? escapeHtml(quote) : '')
  }

  function highlight (source) {
    const text = String(source)
    const names = declaredNames(text)
    const output = []

    scanCode(text, (type, value, start, end) => {
      if (type === 'comment') {
        output.push(span('comment', value))
        return
      }
      if (type === 'string') {
        output.push(renderString(value))
        return
      }
      if (type === 'number' || (type === 'word' && VALUE_WORDS.has(value))) {
        output.push(span('literal', value))
        return
      }
      if (type === 'word') {
        const isMethod = previousNonSpace(text, start) === '.' && nextNonSpace(text, end) === '('
        if (isMethod) output.push(span('method', value))
        else if (OBJECT_NAMES.has(value) || names.has(value)) output.push(span('object', value))
        else output.push(escapeHtml(value))
        return
      }
      output.push(escapeHtml(value))
    })

    return output.join('')
  }

  function install () {
    if (typeof document === 'undefined') return

    const init = () => {
      const codePanel = document.querySelector('.code-panel')
      const aceElement = document.getElementById('editor')
      const fallback = document.getElementById('editor-fallback')
      const actions = document.querySelector('.editor-actions')
      if (!codePanel || !fallback || !actions || document.getElementById('syntax-concept-preview')) return

      const preview = document.createElement('pre')
      preview.id = 'syntax-concept-preview'
      preview.className = 'syntax-concept-preview'
      preview.tabIndex = 0
      preview.setAttribute('role', 'button')
      preview.setAttribute('aria-label', '色分けされたコード。クリックすると編集できます。')
      preview.innerHTML = '<code></code>'

      const legend = document.createElement('div')
      legend.className = 'syntax-concept-legend'
      legend.setAttribute('aria-label', 'コードの色の意味')
      legend.innerHTML = [
        '<span><i class="syntax-object-swatch"></i>オブジェクト・変数</span>',
        '<span><i class="syntax-method-swatch"></i>メソッド</span>',
        '<span><i class="syntax-literal-swatch"></i>値</span>',
        '<span><i class="syntax-comment-swatch"></i>コメント</span>',
        '<span><i class="syntax-default-swatch"></i>文法・記号</span>'
      ].join('')

      actions.insertAdjacentElement('beforebegin', legend)
      legend.insertAdjacentElement('beforebegin', preview)

      function aceEditor () {
        return window.ace && aceElement && aceElement.style.display !== 'none'
          ? window.ace.edit('editor')
          : null
      }

      function currentCode () {
        const ace = aceEditor()
        return ace ? ace.getValue() : fallback.value
      }

      function showPreview () {
        preview.querySelector('code').innerHTML = highlight(currentCode()) + '\n'
        preview.hidden = false
        if (aceElement) aceElement.classList.add('syntax-editor-hidden')
        fallback.classList.add('syntax-editor-hidden')
        codePanel.classList.add('syntax-preview-active')
      }

      function showEditor () {
        preview.hidden = true
        if (aceElement) aceElement.classList.remove('syntax-editor-hidden')
        fallback.classList.remove('syntax-editor-hidden')
        codePanel.classList.remove('syntax-preview-active')
        const ace = aceEditor()
        if (ace) ace.focus()
        else fallback.focus()
      }

      preview.addEventListener('click', showEditor)
      preview.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault()
          showEditor()
        }
      })
      fallback.addEventListener('focus', () => {
        preview.hidden = true
        fallback.classList.remove('syntax-editor-hidden')
        codePanel.classList.remove('syntax-preview-active')
      })
      fallback.addEventListener('blur', showPreview)

      const ace = aceEditor()
      if (ace) {
        ace.on('focus', () => {
          preview.hidden = true
          aceElement.classList.remove('syntax-editor-hidden')
          codePanel.classList.remove('syntax-preview-active')
        })
        ace.on('blur', showPreview)
      }

      document.addEventListener('jsquest:missionloaded', () => window.setTimeout(showPreview, 0))
      document.addEventListener('jsquest:adminanswerdisplayed', () => window.setTimeout(showPreview, 0))
      window.setTimeout(showPreview, 0)
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init)
    else init()
  }

  return Object.freeze({
    highlight,
    declaredNames,
    install
  })
})
