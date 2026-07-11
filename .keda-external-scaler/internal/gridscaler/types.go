package gridscaler

type SeleniumResponse struct {
	Data Data `json:"data"`
}

type Data struct {
	Grid         Grid         `json:"grid"`
	NodesInfo    NodesInfo    `json:"nodesInfo"`
	SessionsInfo SessionsInfo `json:"sessionsInfo"`
}

type Grid struct {
	SessionCount int64 `json:"sessionCount"`
	MaxSession   int64 `json:"maxSession"`
	TotalSlots   int64 `json:"totalSlots"`
}

type NodesInfo struct {
	Nodes Nodes `json:"nodes"`
}

type SessionsInfo struct {
	SessionQueueRequests []string `json:"sessionQueueRequests"`
}

type Nodes []struct {
	ID           string   `json:"id"`
	Status       string   `json:"status"`
	SessionCount int64    `json:"sessionCount"`
	MaxSession   int64    `json:"maxSession"`
	SlotCount    int64    `json:"slotCount"`
	Stereotypes  string   `json:"stereotypes"`
	Sessions     Sessions `json:"sessions"`
}

type ReservedNodes struct {
	ID         string `json:"id"`
	MaxSession int64  `json:"maxSession"`
	SlotCount  int64  `json:"slotCount"`
}

type Sessions []struct {
	ID           string `json:"id"`
	Capabilities string `json:"capabilities"`
	Slot         Slot   `json:"slot"`
}

type Slot struct {
	ID         string `json:"id"`
	Stereotype string `json:"stereotype"`
}

type Stereotypes []struct {
	Slots      int64                  `json:"slots"`
	Stereotype map[string]interface{} `json:"stereotype"`
}

const EnableManagedDownloadsCapability = "se:downloadsEnabled"

var ExtensionCapabilitiesPrefixes = []string{"goog:", "moz:", "ms:", "se:"}
var FunctionCapabilitiesPrefixes = []string{EnableManagedDownloadsCapability}
