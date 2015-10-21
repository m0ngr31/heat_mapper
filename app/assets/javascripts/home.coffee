# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  options =
    ajax: ""
    prevNext:false
    autoWidth: false
    autoHeight: true
    continous: false
    history:true
    numericText:['intro', 'states', 'route']

  sudoSlider = $("#slider").sudoSlider(options)

  selectedStates = []
  state = {}

  $("select").material_select()

  $("#nonresident").attr "disabled", true
  $("#add-state").addClass "disabled"
  $("#route-btn").addClass "disabled"
  $("#loading").hide()

  $("select").on "change", ->
    state = _.find(states,
      name: this.value
    )

    $("#nonresident").prop "checked", false
    $("#add-state").removeClass "disabled"

    unless state.nonresident
      $("#nonresident").attr "disabled", true
    else
      $("#nonresident").removeAttr "disabled"

  $("#add-state").click ->
    unless $("#add-state").hasClass("disabled")
      stateToAdd =
        name: state.name
        nonresident: $("#nonresident").prop "checked"

      selectedStates.push stateToAdd
      selectedStates = _.uniq(selectedStates, 'name')

      showChips()

  $("#route-btn").click ->
    unless $("#route-btn").hasClass("disabled")
      sudoSlider.goToSlide('next')

  $("#states-btn").click ->
    sudoSlider.goToSlide('next')

  $("#back-btn").click ->
    sudoSlider.goToSlide('prev')

  $("#maps-btn").click ->
    unless selectedStates.length > 0
      sudoSlider.goToSlide('prev')
      Materialize.toast "You need to enter at least one permit", 2000, "rounded orange darken-2"
    else
      if $("#departing_city").val().length > 3 and $("#destination_city").val().length > 3
        $("#cards").hide()
        $("#nav-mobile").show()
        $("#loading").show()
        calcRoute()

  showChips = ->
    htmlText = ""

    if selectedStates.length > 0
      $("#route-btn").removeClass "disabled"
      _.each selectedStates, (state) ->
        htmlText += "<div class='chip'>" + state.name
        htmlText += (if state.nonresident then " Non-resident" else "")
        htmlText += "<i class='material-icons' onclick=\"removeState(\'" + state.name + "\')\">close</i></div>"
    else
      htmlText = "<br/>"
      $("#route-btn").addClass "disabled"

    $("#chips").html htmlText

  @removeState = (stateName) ->
    _.remove selectedStates,
      name: stateName

    showChips()

  calcRoute = ->
    origin = $("#departing_city").val()
    destination = $("#destination_city").val()
    request =
      origin: origin
      destination: destination
      travelMode: google.maps.TravelMode.DRIVING

    directionsService.route request, (response, status) ->
      if status is google.maps.DirectionsStatus.OK
        directionsDisplay.setDirections response
        console.log response
        $("#loading").hide()
      else
        $("#loading").hide()
        $("#cards").show()
        $("#nav-mobile").hide()
        Materialize.toast "Could not find a route. Please try again", 3000, "rounded orange darken-2"
