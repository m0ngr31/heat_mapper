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
  travelableStates = []
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
    travelableStates = []

    if selectedStates.length > 0
      $("#route-btn").removeClass "disabled"
      _.each selectedStates, (state) ->
        htmlText += "<div class='chip'>" + state.name

        stateFull = _.find(states,
          name: state.name
        )

        if state.nonresident
          htmlText += " Non-resident"
          travelableStates = _.union travelableStates, stateFull.nonresidentrec
        else
          travelableStates = _.union travelableStates, stateFull.residentrec

        htmlText += "<i class='material-icons' onclick=\"removeState(\'" + state.name + "\')\">close</i></div>"
    else
      htmlText = "<br/>"
      $("#route-btn").addClass "disabled"

    travelableStates = _.uniq travelableStates
    $("#chips").html htmlText

  @removeState = (stateName) ->
    _.remove selectedStates,
      name: stateName

    showChips()

  findBestRoute = (routes) ->
    bestRouteId = 0
    numOfBadStates = 0;

    _.each routes, (route, index) ->
      highlightedStates = []
      starting = route.legs[0].start_address

      if starting.substr(starting.length - 3) is "USA"
        starting = starting.replace /[0-9]/g, ""
        starting = starting.replace /\s/g, ""
        starting = starting.substring(starting.indexOf(",") + 1)
        stateAbbv = starting.substr 0, starting.indexOf(",")

        firstState = _.find(states,
          abbv: stateAbbv
        )

        if firstState
          highlightedStates.push firstState.name

        _.each route.legs[0].steps, (step) ->
          isEntering = step.instructions.search("Entering ")
          manyPassing = (step.instructions.match(/Passing through /g) or []).length
          manyPassing2 = (step.instructions.match(/'Passing through '/g) or []).length

          if isEntering > -1
            indexState = isEntering + 9
            startingString = step.instructions.substring(indexState)
            indexEnd = startingString.search("</div>")
            stateName = startingString.substring(0, indexEnd)
            highlightedStates.push stateName

          #console.log "1: " + manyPassing
          #console.log "2: " + manyPassing2

      console.log _.uniq highlightedStates

    return routes[0]

  calcRoute = ->
    origin = $("#departing_city").val()
    destination = $("#destination_city").val()
    request =
      origin: origin
      destination: destination
      provideRouteAlternatives: true
      travelMode: google.maps.TravelMode.DRIVING

    directionsService.route request, (response, status) ->
      if status is google.maps.DirectionsStatus.OK
        if response.routes.length > 1
          response.routes[0] = findBestRoute response.routes
        directionsDisplay.setDirections response
        console.log response
        $("#loading").hide()
      else
        $("#loading").hide()
        $("#cards").show()
        $("#nav-mobile").hide()
        Materialize.toast "Could not find a route. Please try again", 3000, "rounded orange darken-2"
