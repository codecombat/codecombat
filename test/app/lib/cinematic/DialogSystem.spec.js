/* eslint-env jasmine */
import { processText, wrapText } from '../../../../ozaria/engine/cinematic/dialogsystem/helper'

const dialogNode = text => ({ text })

describe('processText', () => {
  describe('text processing', () => {
    it('letters wrapped with "<l>" and words wrapped with "<x>"', () => {
      const tests = [
        ['<div>hi</div>', '<div><x><l>h</l><l>i</l></x></div>'],
        ['<div>hi world</div>', `<div><x><l>h</l><l>i</l></x> <x><l>w</l><l>o</l><l>r</l><l>l</l><l>d</l></x></div>`]
      ]
      for (const [input, expected] of tests) {
        expect(wrapText(input, l => `<l>${l}</l>`, s => `<x>${s}</x>`)).toEqual(expected)
      }
    })

    it('simple word wrapping with "<x><word></x>', () => {
      const tests = [
        ['<div>hi</div>', `<div><x>hi</x></div>`],
        ['<span>hello, world</span>', '<span><x>hello,</x> <x>world</x></span>']
      ]
      for (const [input, expected] of tests) {
        expect(wrapText(input, l => l, s => `<x>${s}</x>`)).toEqual(expected)
      }
    })

    it('non html strings ignore', () => {
      const tests = [
        '',
        'a',
        'abcd',
        '<no<closing<tag'
      ]

      for (const test of tests) {
        expect(wrapText(test)).toEqual(test)
      }
    })
  })

  describe('processText', () => {
    it('simple text interpolation', () => {
      const name = 'Test User Name'
      const context = ({ name })
      const tests = [
        [`Hello, {%=o.name%}`, `Hello, ${name}`],
        [`Hello, {%=o.unfound%}`, `Hello, `]
      ]

      for (const [template, expected] of tests) {
        expect(processText(dialogNode(template), context, false)).toEqual(expected)
      }
    })
  })
})
