package gridscaler

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/go-logr/logr"
)

// Follow pattern in https://github.com/SeleniumHQ/selenium/blob/trunk/java/src/org/openqa/selenium/grid/data/DefaultSlotMatcher.java
func filterCapabilities(capabilities map[string]interface{}) map[string]interface{} {
	filteredCapabilities := map[string]interface{}{}

	for key, value := range capabilities {
		retain := true
		for _, excludePrefix := range ExtensionCapabilitiesPrefixes {
			if strings.HasPrefix(key, excludePrefix) {
				retain = false
				break
			}
		}
		for _, prefix := range FunctionCapabilitiesPrefixes {
			if strings.HasPrefix(key, prefix) {
				retain = true
				break
			}
		}
		if retain {
			filteredCapabilities[key] = value
		}
	}

	return filteredCapabilities
}

func parseCapabilitiesToMap(_capabilities string) (map[string]interface{}, error) {
	capabilities := map[string]interface{}{}
	if _capabilities != "" {
		if err := json.Unmarshal([]byte(_capabilities), &capabilities); err != nil {
			return nil, err
		}
	}
	return capabilities, nil
}

func getCapability(capability map[string]interface{}, key string) string {
	value, ok := capability[key]
	if ok {
		return value.(string)
	}
	return ""
}

func getBrowserName(capability map[string]interface{}) string {
	return getCapability(capability, "browserName")
}

func getBrowserVersion(capability map[string]interface{}) string {
	return getCapability(capability, "browserVersion")
}

func getPlatformName(capability map[string]interface{}) string {
	return getCapability(capability, "platformName")
}

func countMatchingSlotsStereotypes(stereotypes Stereotypes, browserName string, browserVersion string, sessionBrowserName string, platformName string, capabilities map[string]interface{}) int64 {
	var matchingSlots int64
	for _, stereotype := range stereotypes {
		if checkStereotypeCapabilitiesMatch(stereotype.Stereotype, browserName, browserVersion, sessionBrowserName, platformName, capabilities) {
			matchingSlots += stereotype.Slots
		}
	}
	return matchingSlots
}

func countMatchingSessions(sessions Sessions, browserName string, browserVersion string, sessionBrowserName string, platformName string, capabilities map[string]interface{}, logger logr.Logger) int64 {
	var matchingSessions int64
	for _, session := range sessions {
		var capability map[string]interface{}
		if err := json.Unmarshal([]byte(session.Slot.Stereotype), &capability); err == nil {
			if checkStereotypeCapabilitiesMatch(capability, browserName, browserVersion, sessionBrowserName, platformName, capabilities) {
				matchingSessions++
			}
		} else {
			logger.Error(err, fmt.Sprintf("Error when unmarshaling session capabilities: %s", err))
		}
	}
	return matchingSessions
}

func managedDownloadsEnabled(stereotype map[string]interface{}, capabilities map[string]interface{}) bool {
	// First lets check if user wanted a Node with managed downloads enabled
	value1, ok1 := capabilities[EnableManagedDownloadsCapability]
	if !ok1 || !value1.(bool) {
		// User didn't ask. So lets move on to the next matching criteria
		return true
	}
	// User wants managed downloads enabled to be done on this Node, let's check the stereotype
	value2, ok2 := stereotype[EnableManagedDownloadsCapability]
	// Try to match what the user requested
	return ok2 && value2.(bool)
}

func extensionCapabilitiesMatch(stereotype map[string]interface{}, capabilities map[string]interface{}) bool {
	capabilities = filterCapabilities(capabilities)
	if len(capabilities) == 0 {
		return true
	}
	for key, value := range capabilities {
		if key == EnableManagedDownloadsCapability {
			continue
		}
		if stereotypeValue, ok := stereotype[key]; !ok || stereotypeValue != value {
			return false
		}
	}
	return true
}

// This function checks if the request capabilities match the scaler metadata
func checkRequestCapabilitiesMatch(request map[string]interface{}, browserName string, browserVersion string, _ string, platformName string, capabilities map[string]interface{}) bool {
	// Check if browserName matches
	_browserName := getBrowserName(request)
	browserNameMatch := (_browserName == "" && browserName == "") ||
		strings.EqualFold(browserName, _browserName)

	// Check if browserVersion matches
	_browserVersion := getBrowserVersion(request)
	browserVersionMatch := (_browserVersion == "" && browserVersion == "") ||
		(_browserVersion != "" && strings.HasPrefix(browserVersion, _browserVersion))

	// Check if platformName matches
	platformNameMatch := strings.EqualFold(GetPlatform(platformName).name, GetPlatform(getPlatformName(request)).name) ||
		isSameFamily(GetPlatform(platformName), GetPlatform(getPlatformName(request)))

	return browserNameMatch && browserVersionMatch && platformNameMatch && managedDownloadsEnabled(capabilities, request) && extensionCapabilitiesMatch(request, capabilities)
}

// This function checks if Node stereotypes or ongoing sessions match the scaler metadata
func checkStereotypeCapabilitiesMatch(capability map[string]interface{}, browserName string, browserVersion string, sessionBrowserName string, platformName string, capabilities map[string]interface{}) bool {
	// Check if browserName matches
	_browserName := getBrowserName(capability)
	browserNameMatch := (_browserName == "" && browserName == "") ||
		strings.EqualFold(browserName, _browserName) ||
		strings.EqualFold(sessionBrowserName, _browserName)

	// Check if browserVersion matches
	_browserVersion := getBrowserVersion(capability)
	browserVersionMatch := (_browserVersion == "" && browserVersion == "") ||
		(_browserVersion != "" && strings.HasPrefix(browserVersion, _browserVersion))

	// Check if platformName matches
	platformNameMatch := strings.EqualFold(GetPlatform(platformName).name, GetPlatform(getPlatformName(capability)).name) ||
		isSameFamily(GetPlatform(platformName), GetPlatform(getPlatformName(capability)))

	return browserNameMatch && browserVersionMatch && platformNameMatch && managedDownloadsEnabled(capabilities, capability) && extensionCapabilitiesMatch(capability, capabilities)
}

func checkNodeReservedSlots(reservedNodes []ReservedNodes, nodeID string, availableSlots int64) int64 {
	for _, reservedNode := range reservedNodes {
		if strings.EqualFold(reservedNode.ID, nodeID) {
			return reservedNode.SlotCount
		}
	}
	return availableSlots
}

func updateOrAddReservedNode(reservedNodes []ReservedNodes, nodeID string, slotCount int64, maxSession int64) []ReservedNodes {
	for i, reservedNode := range reservedNodes {
		if strings.EqualFold(reservedNode.ID, nodeID) {
			// Update remaining available slots for the reserved node
			reservedNodes[i].SlotCount = slotCount
			return reservedNodes
		}
	}
	// Add new reserved node if not found
	return append(reservedNodes, ReservedNodes{ID: nodeID, SlotCount: slotCount, MaxSession: maxSession})
}

func getCountFromSeleniumResponse(b []byte, browserName string, browserVersion string, sessionBrowserName string, platformName string, nodeMaxSessions int64, enableManagedDownloads bool, _capabilities string, logger logr.Logger) (int64, int64, error) {
	// Track number of available slots of existing Nodes in the Grid can be reserved for the matched requests
	var availableSlots int64
	// Track number of matched requests in the sessions queue will be served by this scaler
	var queueSlots int64

	var seleniumResponse = SeleniumResponse{}
	if err := json.Unmarshal(b, &seleniumResponse); err != nil {
		return 0, 0, err
	}

	capabilities, err := parseCapabilitiesToMap(_capabilities)
	if err != nil {
		logger.Error(err, fmt.Sprintf("Error when unmarshaling trigger metadata 'capabilities': %s", err))
	}
	if enableManagedDownloads {
		capabilities[EnableManagedDownloadsCapability] = true
	}

	var sessionQueueRequests = seleniumResponse.Data.SessionsInfo.SessionQueueRequests
	var nodes = seleniumResponse.Data.NodesInfo.Nodes
	// Track list of existing Nodes that have available slots for the matched requests
	var reservedNodes []ReservedNodes
	// Track list of new Nodes will be scaled up with number of available slots following scaler parameter `nodeMaxSessions`
	var newRequestNodes []ReservedNodes
	var onGoingSessions int64
	for requestIndex, sessionQueueRequest := range sessionQueueRequests {
		var isRequestMatched bool
		var requestCapability map[string]interface{}
		if err := json.Unmarshal([]byte(sessionQueueRequest), &requestCapability); err == nil {
			if checkRequestCapabilitiesMatch(requestCapability, browserName, browserVersion, sessionBrowserName, platformName, capabilities) {
				queueSlots++
				isRequestMatched = true
			}
		} else {
			logger.Error(err, fmt.Sprintf("Error when unmarshaling sessionQueueRequest capability: %s", err))
		}

		var isRequestReserved bool
		// Check if the matched request can be assigned to available slots of existing Nodes in the Grid
		for _, node := range nodes {
			// Check if node is UP and has available slots (maxSession > sessionCount)
			if isRequestMatched && strings.EqualFold(node.Status, "UP") && checkNodeReservedSlots(reservedNodes, node.ID, node.MaxSession-node.SessionCount) > 0 {
				var stereotypes = Stereotypes{}
				var availableSlotsMatch int64
				if err := json.Unmarshal([]byte(node.Stereotypes), &stereotypes); err == nil {
					// Count available slots that match the request capability and scaler metadata
					availableSlotsMatch += countMatchingSlotsStereotypes(stereotypes, browserName, browserVersion, sessionBrowserName, platformName, capabilities)
				} else {
					logger.Error(err, fmt.Sprintf("Error when unmarshaling node stereotypes: %s", err))
				}
				if availableSlotsMatch == 0 {
					continue
				}
				// Count ongoing sessions that match the request capability and scaler metadata
				var currentSessionsMatch = countMatchingSessions(node.Sessions, browserName, browserVersion, sessionBrowserName, platformName, capabilities, logger)
				// Count remaining available slots can be reserved for this request
				var availableSlotsCanBeReserved = checkNodeReservedSlots(reservedNodes, node.ID, node.MaxSession-node.SessionCount)
				// Reserve one available slot for the request if available slots match is greater than current sessions match
				if availableSlotsMatch > currentSessionsMatch {
					availableSlots++
					reservedNodes = updateOrAddReservedNode(reservedNodes, node.ID, availableSlotsCanBeReserved-1, node.MaxSession)
					isRequestReserved = true
					break
				}
			}
		}
		// Check if the matched request can be assigned to available slots of new Nodes will be scaled up, since the scaler parameter `nodeMaxSessions` can be greater than 1
		if isRequestMatched && !isRequestReserved {
			for _, newRequestNode := range newRequestNodes {
				if newRequestNode.SlotCount > 0 {
					newRequestNodes = updateOrAddReservedNode(newRequestNodes, newRequestNode.ID, newRequestNode.SlotCount-1, nodeMaxSessions)
					isRequestReserved = true
					break
				}
			}
		}
		// Check if a new Node should be scaled up to reserve for the matched request
		if isRequestMatched && !isRequestReserved {
			newRequestNodes = updateOrAddReservedNode(newRequestNodes, string(rune(requestIndex)), nodeMaxSessions-1, nodeMaxSessions)
		}
	}

	// Count ongoing sessions across all nodes that match the scaler metadata
	for _, node := range nodes {
		onGoingSessions += countMatchingSessions(node.Sessions, browserName, browserVersion, sessionBrowserName, platformName, capabilities, logger)
	}

	return int64(len(newRequestNodes)), onGoingSessions, nil
}
