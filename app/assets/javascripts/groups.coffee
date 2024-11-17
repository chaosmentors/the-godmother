# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  table = $('#person-datatable').dataTable
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
  
  highlightTags = ->
    mentorTags = []
    $('#current_group_mentors tbody tr').each (index, row) ->
      tags = $(row).find('td:eq(3)').text().split(', ')
      mentorTags = mentorTags.concat(tags)

    mentorTags = $.unique(mentorTags)

    $('#person-datatable tbody tr').each (index, row) ->
      tagsCell = $(row).find('td:eq(5)')
      tags = tagsCell.text().split(', ')
      highlightedTags = tags.map (tag) ->
        if tag in mentorTags
          "<mark>#{tag}</mark>"
        else
          tag
      tagsCell.html(highlightedTags.join(', '))

  $('#person-datatable').on 'draw.dt', ->
    highlightTags()

  highlightTags()

  # We really need better state management here! Maybe a different approach?
  # This is a quick and dirty way to keep track of the selected rows

  # Checkbox click in person-datatable
  $('#person-datatable').on 'change', 'input[type="checkbox"]', (event) ->
    checkbox = $(event.target)
    row = checkbox.closest('tr')
    rowId = row.find('input[type="checkbox"]').val()

    if checkbox.prop('checked')
      # Check if the row already exists in the current_group_mentees table
      existingCheckbox = $('#current_group_mentees tbody input[type="checkbox"][value="' + rowId + '"]')
      if existingCheckbox.length == 0
        clonedRow = row.clone()
        clonedRow.find('input[type="checkbox"]').prop('checked', true)
        # Remove the email column (third column)
        clonedRow.find('td:eq(3)').remove()
        $('#current_group_mentees tbody').append(clonedRow)
      else
        # Check the corresponding checkbox in the current_group_mentees table
        existingCheckbox.prop('checked', true)
    else
      # Remove the row from the current_group_mentees table
      $('#current_group_mentees tbody input[type="checkbox"][value="' + rowId + '"]').closest('tr').remove()

  # Checkbox click in current_group_mentees
  $('#current_group_mentees').on 'change', 'input[type="checkbox"]', (event) ->
    checkbox = $(event.target)
    rowId = checkbox.val()
    # Toggle the corresponding checkbox in the person-datatable
    $('#person-datatable tbody input[type="checkbox"][value="' + rowId + '"]').prop('checked', checkbox.prop('checked'))

  # DataTable draw event
  $('#person-datatable').on 'draw.dt', ->
    # Iterate over each checkbox in the current_group_mentees table
    $('#current_group_mentees tbody input[type="checkbox"]').each (index, element) ->
      rowId = $(element).val()
      # Update the corresponding checkbox in the person-datatable based on the original checkbox state
      $('#person-datatable tbody input[type="checkbox"][value="' + rowId + '"]').prop('checked', $(element).prop('checked'))

    highlightTags()