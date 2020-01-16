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
        [`Hello, {%=o.name%}`, `<div><p><span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">H</span><span class="letter" style="display: inline-block; opacity:0">e</span><span class="letter" style="display: inline-block; opacity:0">l</span><span class="letter" style="display: inline-block; opacity:0">l</span><span class="letter" style="display: inline-block; opacity:0">o</span><span class="letter" style="display: inline-block; opacity:0">,</span></span> <span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">T</span><span class="letter" style="display: inline-block; opacity:0">e</span><span class="letter" style="display: inline-block; opacity:0">s</span><span class="letter" style="display: inline-block; opacity:0">t</span></span> <span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">U</span><span class="letter" style="display: inline-block; opacity:0">s</span><span class="letter" style="display: inline-block; opacity:0">e</span><span class="letter" style="display: inline-block; opacity:0">r</span></span> <span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">N</span><span class="letter" style="display: inline-block; opacity:0">a</span><span class="letter" style="display: inline-block; opacity:0">m</span><span class="letter" style="display: inline-block; opacity:0">e</span></span></p></div>`],
        [`Hello, {%=o.unfound%}`, `<div><p><span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">H</span><span class="letter" style="display: inline-block; opacity:0">e</span><span class="letter" style="display: inline-block; opacity:0">l</span><span class="letter" style="display: inline-block; opacity:0">l</span><span class="letter" style="display: inline-block; opacity:0">o</span><span class="letter" style="display: inline-block; opacity:0">,</span></span> </p></div>`]
      ]

      for (const [template, expected] of tests) {
        expect(processText(dialogNode(template), context)).toEqual(expected)
      }
    })

    it('handle markdown', () => {
      const tests = [
        [`Hey *italic*!`, `<div><p><span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">H</span><span class="letter" style="display: inline-block; opacity:0">e</span><span class="letter" style="display: inline-block; opacity:0">y</span></span> <em><span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">i</span><span class="letter" style="display: inline-block; opacity:0">t</span><span class="letter" style="display: inline-block; opacity:0">a</span><span class="letter" style="display: inline-block; opacity:0">l</span><span class="letter" style="display: inline-block; opacity:0">i</span><span class="letter" style="display: inline-block; opacity:0">c</span></span></em><span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">!</span></span></p></div>`],
        [`# A heading!!!`, `<div><h1 id="a-heading-"><span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">A</span></span> <span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">h</span><span class="letter" style="display: inline-block; opacity:0">e</span><span class="letter" style="display: inline-block; opacity:0">a</span><span class="letter" style="display: inline-block; opacity:0">d</span><span class="letter" style="display: inline-block; opacity:0">i</span><span class="letter" style="display: inline-block; opacity:0">n</span><span class="letter" style="display: inline-block; opacity:0">g</span><span class="letter" style="display: inline-block; opacity:0">!</span><span class="letter" style="display: inline-block; opacity:0">!</span><span class="letter" style="display: inline-block; opacity:0">!</span></span></h1></div>`],
        [`**bold**`, `<div><p><strong><span class="word" style="display: inline-block; whites-space: nowrap"><span class="letter" style="display: inline-block; opacity:0">b</span><span class="letter" style="display: inline-block; opacity:0">o</span><span class="letter" style="display: inline-block; opacity:0">l</span><span class="letter" style="display: inline-block; opacity:0">d</span></span></strong></p></div>`]
      ]

      for (const [template, expected] of tests) {
        expect(processText(dialogNode(template), {})).toEqual(expected)
      }
    })
  })
})
