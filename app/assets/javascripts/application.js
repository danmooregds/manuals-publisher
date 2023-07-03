/* global pasteHtmlToGovspeak */
//= require vendor/jquery-1.11.0.min
//= require vendor/jquery-ui.min.js

//= require govuk_toolkit
//= require ajax_setup
//= require length_counter
//= require markdown_preview
//= require toggle_display_with_checked_input
//= require paste-html-to-govspeak
//= require govuk_publishing_components/dependencies
//= require govuk_publishing_components/all_components
jQuery(function ($) {
  $('.js-length-counter').each(function () {
    new GOVUK.LengthCounter({ $el: $(this) }) // eslint-disable-line no-new
  })

  $('.js-paste-html-to-govspeak').each(function () {
    this.addEventListener('paste', pasteHtmlToGovspeak.pasteListener)
  })

  $('.reorderable-document-list').sortable()
})
