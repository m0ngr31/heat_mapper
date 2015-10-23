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
    history: true
    useCSS: true
    speed: "normal"
    numericText: ['into', 'states', 'route', 'help']

  sudoSlider = $("#slider").sudoSlider(options)

  selectedStates = []
  travelableStates = []
  polygons = []
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

  $("#help-btn").click ->
    window.location.hash = "#route"

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

  getStatesFromDirections = (route) ->
    highlightedStates = []
    starting = route.legs[0].start_address

    if starting.substr(starting.length - 3) is "USA"
      starting = starting.replace /[0-9]/g, ""
      starting = starting.replace /\s/g, ""
      starting = starting.substr 0, starting.lastIndexOf(",")
      stateAbbv = starting.substring(starting.lastIndexOf(",") + 1)

      firstState = _.find(states, (state) ->
        state.abbv is stateAbbv or state.name is stateAbbv
      )

      if firstState
        highlightedStates.push firstState.name

    _.each route.legs[0].steps, (step) ->
      isEntering = step.instructions.search("Entering ")
      isPassing = step.instructions.search("Passing through ")
      isEnteringUSA = step.instructions.search("Entering the United States of America ")

      if isEntering > -1
        indexState = isEntering + 9
        startingString = step.instructions.substring(indexState)
        indexEnd = startingString.search("</div>")
        stateName = startingString.substring(0, indexEnd)
        highlightedStates.push stateName

      if isEnteringUSA > -1
        indexState3 = isEntering + 39
        startingString3 = step.instructions.substring(indexState3)
        indexEnd3 = startingString3.search("\\)")
        stateName3 = startingString3.substring(0, indexEnd3)
        highlightedStates.push stateName3      

      if isPassing > -1
        indexState2 = isPassing + 16
        startingString2 = step.instructions.substring(indexState2)
        indexEnd2 = startingString2.search("</div>")
        stateName2 = startingString2.substring(0, indexEnd2)
        stateName2 = stateName2.trim()
        if stateName2.indexOf(",") isnt -1
          count2 = 0
          
          i = 0
          while i < stateName2.length
            count2++  if stateName2.charAt(i) is ","
            i++

          z = 0
          while z < count2
            stateTemp = stateName2.substring(0, stateName2.indexOf(","))
            stateName2 = stateName2.substring(stateName2.indexOf(",") + 2)
            highlightedStates.push stateTemp
            z++
          highlightedStates.push stateName2
        else
          highlightedStates.push stateName2
      
    highlightedStates = _.uniq highlightedStates
    routeBadStates = _.difference(highlightedStates, travelableStates)
    routeGoodStates = _.difference(highlightedStates, routeBadStates)

    obj =
      allStates: highlightedStates
      badStates: routeBadStates
      goodStates: routeGoodStates

    return obj

  findBestRoute = (routes) ->
    bestRouteId = 0
    numOfBadStates = 0;

    _.each routes, (route, index) ->
      states = getStatesFromDirections(route)

      numOfBadStates = states.badStates.length if index is 0

      if states.badStates.length < numOfBadStates
        numOfBadStates = states.badStates.length
        bestRouteId = index

    return routes[bestRouteId]

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
        $("#loading").hide()
      else
        $("#loading").hide()
        $("#cards").show()
        $("#nav-mobile").hide()
        Materialize.toast "Could not find a route. Please try again", 3000, "rounded orange darken-2"

  highlightStates = (response) ->
    statesObj = getStatesFromDirections(response.routes[0])

    _.each polygons, (state) ->
      state.setMap null

    polygons= []

    _.each statesObj.goodStates, (state) ->
      stateFull = _.find(states,
        name: state
      )

      if stateFull
        statePolygon = handler.addPolygon(
          stateFull.point,
          strokeColor: '#2185c5'
          strokeOpacity: 0.8
          strokeWeight: 2
          fillColor: '#2185c5'
          fillOpacity: 0.35
        )

        polygons.push statePolygon

    _.each statesObj.badStates, (state) ->
      stateFull = _.find(states,
        name: state
      )

      if stateFull
        statePolygon = handler.addPolygon(
          stateFull.point,
          strokeColor: '#FF0000'
          strokeOpacity: 0.8
          strokeWeight: 2
          fillColor: '#FF0000'
          fillOpacity: 0.35
        )

        polygons.push statePolygon

  google.maps.event.addListener directionsDisplay, "directions_changed", ->
    highlightStates directionsDisplay.directions
