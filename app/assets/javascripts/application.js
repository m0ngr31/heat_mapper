// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//

//= require jquery_ujs
//= require turbolinks
//= require_tree .

//= require gmaps/google
//= require lodash
//= require jquery.sudoSlider.min.js


//Stole this from SO:::
$(document).ready(function() {
  $("#nav-mobile").hide();

  $("#nav-mobile").click(function() {
    $("#cards").show();
    $("#nav-mobile").hide();
    $("#loading").hide();
  });

  $("#help").click(function() {
    $("#cards").show();
    $("#nav-mobile").hide();
    $("#loading").hide();
    window.location.hash = "#help";
  });
});

directionsDisplay = new google.maps.DirectionsRenderer({draggable: true});
directionsService = new google.maps.DirectionsService();

function initialize() {
  handler = Gmaps.build('Google');
  handler.buildMap({ 
    provider: {
      zoom:      5,
      center:    new google.maps.LatLng(39.0, -98.35),
      draggable: false,
      scrollwheel: false,
      mapTypeControl: false,
      scaleControl: false,
      disableDoubleClickZoom: true,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }, 
    internal: {id: 'map'}},
    function(){
      directionsDisplay.setMap(handler.getMap());
    });
}

google.maps.event.addDomListener(window, "load", initialize);