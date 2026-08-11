package gridscaler

import "testing"

// Test_parseMetadata_errorsAndNil covers the remaining parseMetadata branches:
// a nil scalerMetadata map (no url → error) and the numeric/boolean parse
// failures for nodeMaxSessions, unsafeSsl and enableManagedDownloads.
func Test_parseMetadata_errorsAndNil(t *testing.T) {
	tests := []struct {
		name string
		meta map[string]string
	}{
		{"nil metadata has no url and errors", nil},
		{
			"invalid nodeMaxSessions errors",
			map[string]string{"url": "http://g", "browserName": "chrome", "nodeMaxSessions": "notint"},
		},
		{
			"invalid unsafeSsl errors",
			map[string]string{"url": "http://g", "browserName": "chrome", "unsafeSsl": "notbool"},
		},
		{
			"invalid enableManagedDownloads errors",
			map[string]string{"url": "http://g", "browserName": "chrome", "enableManagedDownloads": "notbool"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if _, err := parseMetadata(tt.meta, nil); err == nil {
				t.Errorf("parseMetadata() error = nil, want non-nil")
			}
		})
	}
}

// Test_parseMetadata_nodeMaxSessions confirms a valid nodeMaxSessions is parsed
// so the success side of that branch is also exercised.
func Test_parseMetadata_nodeMaxSessions(t *testing.T) {
	meta, err := parseMetadata(map[string]string{
		"url":             "http://g",
		"browserName":     "chrome",
		"nodeMaxSessions": "5",
	}, nil)
	if err != nil {
		t.Fatalf("parseMetadata() error = %v", err)
	}
	if meta.NodeMaxSessions != 5 {
		t.Errorf("NodeMaxSessions = %d, want 5", meta.NodeMaxSessions)
	}
}
