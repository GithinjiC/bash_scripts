package main

// import (
// 	// "fmt"
// 	"html/template"
// 	"log"
// 	"net/http"
// )

// func main() {
// 	// Start the server to serve the map
// 	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
// 		// Create a template for the HTML page
// 		tmpl := `
// <!DOCTYPE html>
// <html>
// <head>
//     <title>Your Location on Map</title>
//     <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY&callback=initMap" async defer></script>
//     <script>
//         var map;

//         // Function to initialize the map
//         function initMap() {
//             map = new google.maps.Map(document.getElementById("map"), {
//                 zoom: 10,
//             });

//             // Try to get user's current location using Geolocation API
//             if (navigator.geolocation) {
//                 navigator.geolocation.getCurrentPosition(function(position) {
//                     var userLat = position.coords.latitude;
//                     var userLng = position.coords.longitude;

//                     // Set map center to the user's location
//                     var userLocation = new google.maps.LatLng(userLat, userLng);
//                     map.setCenter(userLocation);

//                     // Add a marker at the user's location
//                     var marker = new google.maps.Marker({
//                         position: userLocation,
//                         map: map,
//                         title: "You are here!"
//                     });
//                 }, function() {
//                     alert("Geolocation failed or is not supported by this browser.");
//                 });
//             } else {
//                 alert("Geolocation is not supported by this browser.");
//             }
//         }
//     </script>
// </head>
// <body onload="initMap()">
//     <h1>Your Location on Map</h1>
//     <div id="map" style="height: 600px; width: 100%;"></div>
// </body>
// </html>
// `

// 		// Parse and execute the template
// 		t, err := template.New("map").Parse(tmpl)
// 		if err != nil {
// 			http.Error(w, "Error generating the map template", http.StatusInternalServerError)
// 			log.Fatal(err)
// 		}

// 		// Execute the template
// 		err = t.Execute(w, nil)
// 		if err != nil {
// 			http.Error(w, "Error rendering the map", http.StatusInternalServerError)
// 			log.Fatal(err)
// 		}
// 	})

// 	// Start the HTTP server
// 	port := ":8080"
// 	log.Printf("Server starting on port %s...\n", port)
// 	err := http.ListenAndServe(port, nil)
// 	if err != nil {
// 		log.Fatal("Error starting the server:", err)
// 	}
// }
