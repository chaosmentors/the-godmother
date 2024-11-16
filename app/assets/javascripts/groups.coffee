# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('#person-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: $('#person-datatable').data('source')
    pagingType: 'simple_numbers'
    pageLength: 25
    columns: [
      {data: 'id'}
      {data: 'pronoun'}
      {data: 'name'}
      {data: 'email'}
      {data: 'about'}
      {data: 'tags'}
    ]