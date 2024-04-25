package main 

import (
	"io/ioutil"
	"log"
	"net/http"
	"fmt"
	"encoding/json"
	"os"
)

type Latest struct {
	Images []struct {
		Architecture string `json:"architecture"`
                Digest string `json:"digest"`
	}
}


func main() {
    argLen := len(os.Args)
    if argLen < 2 {
	    showUsage()
	    os.Exit(1)
    }

    url := os.Args[1]   // https://hub.docker.com/v2/repositories/selenium/standalone-chrome/tags/latest/
    resp, err := http.Get(url)
    if err != nil {
	log.Fatalln(err)
    }

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
	    log.Fatalln(err)
    }

    var jsonResp Latest
    sb := string(body)
    json.Unmarshal([]byte(sb), &jsonResp)
    
    for _, image := range jsonResp.Images {
        fmt.Printf(image.Architecture + " " + image.Digest + "\n")
    }    
}

func showUsage() {
	fmt.Println(`Usage: 
    get-image-sha256-digest TAG_URL

    TAG_URL -> URL for a container image manifest (Required)

    Example Usage:
    $ get-image-sha256-digest https://hub.docker.com/v2/repositories/selenium/standalone-chrome/tags/latest/
    `)
}
