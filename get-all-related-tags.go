package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

type Latest struct {
	Images []struct {
		Architecture string `json:"architecture"`
		Digest       string `json:"digest"`
	}
}

type Result struct {
	Results []struct {
		Images []struct {
			Digest string `json:"digest"`
		}
		Name string `json:"name"`
	}
}

func main() {
	argLen := len(os.Args)
	if argLen < 2 {
		showUsage()
		os.Exit(1)
	}
	url := os.Args[1] // https://hub.docker.com/v2/repositories/selenium/standalone-chrome/tags/latest/
	var inputArch string
	if argLen >= 3 {
		inputArch = os.Args[2]
	}

	if inputArch == "" {
		fmt.Println("Get related tags using sha256 for random architecture...")
	} else {
		fmt.Println("Get related tags using sha256 for " + inputArch + " architecture...")
	}

	arch, tagDigest := getDigestForTag(url, inputArch)
	fmt.Println("getting related tags for " + arch + " digest = " + tagDigest)

	var allTagsUrl string
	var theseRelatedTags []string
	var relatedTagsStr string

	allTagsUrl = getAllTagsUrl(url)
	theseRelatedTags = getRelatedTagsFromDigest(allTagsUrl, tagDigest)
	relatedTagsStr = strings.Join(theseRelatedTags, " ")
	for next := true; next; next = (len(theseRelatedTags) != 0) {
		allTagsUrl = getAllTagsUrlForNextPage(allTagsUrl)
		theseRelatedTags = getRelatedTagsFromDigest(allTagsUrl, tagDigest)
		relatedTagsStr = relatedTagsStr + " " + strings.Join(theseRelatedTags, " ")
		// fmt.Println(theseRelatedTags)
	}

	fmt.Println(relatedTagsStr)
}

func getDigestForTag(url string, inputArch string) (string, string) {
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

	var digest string
	var arch string
	if inputArch != "" {
		for _, image := range jsonResp.Images {
			if inputArch == image.Architecture {
				digest = image.Digest
				arch = image.Architecture
			}
		}
	} else {
		for _, image := range jsonResp.Images {
			digest = image.Digest
			arch = image.Architecture
		}
	}

	return arch, digest
}

func getAllTagsUrlForNextPage(specificTagUrl string) string {
	urlPathArr := strings.Split(specificTagUrl, "?")
	var pageNum string
	if len(urlPathArr) > 1 {
		pageKeyVal := strings.Split(urlPathArr[1], "=")
		pageNumInt, err := strconv.Atoi(pageKeyVal[1])
		if err != nil {
			log.Fatalln(err)
		}
		pageNum = "?page=" + strconv.Itoa(pageNumInt+1)
	} else {
		pageNum = "?page=1"
	}
	return urlPathArr[0] + pageNum
}

func getAllTagsUrl(specificTagUrl string) string {
	urlPathArr := strings.Split(specificTagUrl, "?")
	var pageNum string
	if len(urlPathArr) > 1 {
		pageNum = "?" + urlPathArr[1]
	} else {
		pageNum = "?page=1"
	}

	specificTagUrlWithoutPage := urlPathArr[0]
	urlArr := strings.Split(specificTagUrlWithoutPage, "/")
	// fmt.Println(urlArr[len(urlArr)-1])
	if urlArr[len(urlArr)-1] == "" {
		urlArr[len(urlArr)-1] = ""
		urlArr[len(urlArr)-2] = ""
	} else {
		urlArr[len(urlArr)-1] = ""
	}
	urlArr = urlArr[:len(urlArr)-1]
	allTagsUrl := strings.Join(urlArr, "/") // // https://hub.docker.com/v2/repositories/selenium/standalone-chrome/tags/
	return allTagsUrl + pageNum
}

func getRelatedTagsFromDigest(allTagsUrl string, digest string) []string {

	resp, err := http.Get(allTagsUrl)
	if err != nil {
		log.Fatalln(err)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatalln(err)
	}

	var jsonResp Result
	sb := string(body)
	json.Unmarshal([]byte(sb), &jsonResp)

	var relatedTags []string
	for _, results := range jsonResp.Results {
		for _, image := range results.Images {
			imageDigest := image.Digest
			if imageDigest == digest {
				relatedTags = append(relatedTags, results.Name)
			}
		}
	}
	return relatedTags
}

func showUsage() {
	fmt.Println(`Usage: 
    get-all-related-tags TAG_URL [ARCH]

    TAG_URL -> URL for a container image manifest (Required)
    ARCH    -> Architecture to use to obtain sha256 (Optional)

    Example Usage:
    $ get-all-related-tags https://hub.docker.com/v2/repositories/selenium/standalone-chrome/tags/latest/
    `)
}
