package main

import (
	"io"
	"log"
	"net/http"
)

func main() {

	http.HandleFunc("/", rootHandler)
	http.HandleFunc("/health", healthCheckHandler)
	http.HandleFunc("/reader", readerHandler)
	http.ListenAndServe("0.0.0.0:8080", nil)

}

func rootHandler(w http.ResponseWriter, req *http.Request) {

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_, err := io.WriteString(w,
		"<center>"+
			"<br>Please Read: <br>"+
			"This endpoint has the followings routes: <br>"+
			"/health <br>"+
			"/reader <br>")
	if err != nil {
		log.Fatal(err)
	}

}

func healthCheckHandler(w http.ResponseWriter, req *http.Request) {

	_, err := io.WriteString(w, "OK")
	if err != nil {
		log.Panicln(err)
	}

}

func readerHandler(w http.ResponseWriter, req *http.Request) {

	_, err := io.WriteString(w, "You're allowed to perform read operations")
	if err != nil {
		log.Panicln(err)
	}
}
