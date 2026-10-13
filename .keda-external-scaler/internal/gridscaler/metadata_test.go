package gridscaler

import (
	"reflect"
	"testing"
)

// These cases re-express KEDA's Test_parseSeleniumGridScalerMetadata against the
// external scaler's input model. KEDA's built-in scaler receives url/credentials
// via TriggerAuthentication authParams; an external scaler cannot (KEDA does not
// forward authParams over gRPC), so the equivalent inputs arrive as trigger
// metadata, *FromEnv metadata, or the scaler's own environment. Behaviour under
// test — defaults, required url, enum validation, sessionBrowserName fallback — is
// identical to the built-in scaler.
func Test_parseMetadata(t *testing.T) {
	tests := []struct {
		name    string
		meta    map[string]string
		env     map[string]string
		want    *Metadata
		wantErr bool
	}{
		{
			name:    "missing url should throw error",
			meta:    map[string]string{},
			wantErr: true,
		},
		{
			name:    "empty url should throw error",
			meta:    map[string]string{"url": ""},
			wantErr: true,
		},
		{
			name: "valid url and browsername should return metadata",
			meta: map[string]string{
				"url":         "http://selenium-hub:4444/graphql",
				"browserName": "chrome",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "sessionBrowserName overrides the browserName-derived default",
			meta: map[string]string{
				"url":                "http://selenium-hub:4444/graphql",
				"browserName":        "MicrosoftEdge",
				"sessionBrowserName": "msedge",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "MicrosoftEdge",
				SessionBrowserName:     "msedge",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "empty browserName is allowed",
			meta: map[string]string{
				"url":         "http://selenium-hub:4444/graphql",
				"browserName": "",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "",
				SessionBrowserName:     "",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "username and password from trigger metadata",
			meta: map[string]string{
				"url":                "http://selenium-hub:4444/graphql",
				"browserName":        "MicrosoftEdge",
				"sessionBrowserName": "msedge",
				"username":           "username",
				"password":           "password",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "MicrosoftEdge",
				SessionBrowserName:     "msedge",
				Username:               "username",
				Password:               "password",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "valid capabilities should return metadata",
			meta: map[string]string{
				"url":                    "http://selenium-hub:4444/graphql",
				"browserName":            "MicrosoftEdge",
				"sessionBrowserName":     "msedge",
				"enableManagedDownloads": "true",
				"capabilities":           "{\"myApp:version\": \"beta\"}",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "MicrosoftEdge",
				SessionBrowserName:     "msedge",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				Capabilities:           "{\"myApp:version\": \"beta\"}",
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "browserVersion and unsafeSsl false",
			meta: map[string]string{
				"url":            "http://selenium-hub:4444/graphql",
				"browserName":    "chrome",
				"browserVersion": "91.0",
				"unsafeSsl":      "false",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				BrowserVersion:         "91.0",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "unsafeSsl and activationThreshold",
			meta: map[string]string{
				"url":                 "http://selenium-hub:4444/graphql",
				"browserName":         "chrome",
				"browserVersion":      "91.0",
				"unsafeSsl":           "true",
				"activationThreshold": "10",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				BrowserVersion:         "91.0",
				UnsafeSsl:              true,
				ActivationThreshold:    10,
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "invalid activationThreshold should throw an error",
			meta: map[string]string{
				"url":                 "http://selenium-hub:4444/graphql",
				"browserName":         "chrome",
				"activationThreshold": "AA",
			},
			wantErr: true,
		},
		{
			name: "platformName, nodeMaxSessions and auth",
			meta: map[string]string{
				"url":                 "http://selenium-hub:4444/graphql",
				"browserName":         "chrome",
				"browserVersion":      "91.0",
				"unsafeSsl":           "true",
				"activationThreshold": "10",
				"platformName":        "Windows 11",
				"nodeMaxSessions":     "3",
				"username":            "user",
				"password":            "password",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				Username:               "user",
				Password:               "password",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				BrowserVersion:         "91.0",
				UnsafeSsl:              true,
				ActivationThreshold:    10,
				PlatformName:           "Windows 11",
				NodeMaxSessions:        3,
				TargetValue:            1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "non-Basic auth type with access token",
			meta: map[string]string{
				"url":         "http://selenium-hub:4444/graphql",
				"browserName": "chrome",
				"authType":    "OAuth2",
				"accessToken": "my-access-token",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				AuthType:               "OAuth2",
				AccessToken:            "my-access-token",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "invalid includeOngoingSessions should throw an error",
			meta: map[string]string{
				"url":                    "http://selenium-hub:4444/graphql",
				"browserName":            "chrome",
				"includeOngoingSessions": "bogus",
			},
			wantErr: true,
		},
		{
			name: "includeOngoingSessions can be disabled",
			meta: map[string]string{
				"url":                    "http://selenium-hub:4444/graphql",
				"browserName":            "chrome",
				"includeOngoingSessions": "false",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: false,
			},
		},
		{
			name: "enableManagedDownloads can be disabled",
			meta: map[string]string{
				"url":                    "http://selenium-hub:4444/graphql",
				"browserName":            "chrome",
				"enableManagedDownloads": "false",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: false,
				IncludeOngoingSessions: true,
			},
		},
		// External-scaler-specific: *FromEnv and server-env fallback resolution.
		{
			name: "url and credentials resolved from *FromEnv metadata (KEDA-resolved values)",
			meta: map[string]string{
				"urlFromEnv":      "http://selenium-hub:4444/graphql",
				"usernameFromEnv": "user",
				"passwordFromEnv": "password",
				"browserName":     "chrome",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				Username:               "user",
				Password:               "password",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "url and credentials fall back to scaler environment",
			meta: map[string]string{"browserName": "chrome"},
			env: map[string]string{
				"SE_GRID_URL": "http://selenium-hub:4444/graphql",
				"SE_USERNAME": "envuser",
				"SE_PASSWORD": "envpass",
			},
			want: &Metadata{
				URL:                    "http://selenium-hub:4444/graphql",
				Username:               "envuser",
				Password:               "envpass",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
		{
			name: "trigger metadata takes precedence over environment fallback",
			meta: map[string]string{
				"url":         "http://from-metadata:4444/graphql",
				"browserName": "chrome",
			},
			env: map[string]string{
				"SE_GRID_URL": "http://from-env:4444/graphql",
			},
			want: &Metadata{
				URL:                    "http://from-metadata:4444/graphql",
				BrowserName:            "chrome",
				SessionBrowserName:     "chrome",
				TargetValue:            1,
				NodeMaxSessions:        1,
				EnableManagedDownloads: true,
				IncludeOngoingSessions: true,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := parseMetadata(tt.meta, tt.env)
			if (err != nil) != tt.wantErr {
				t.Errorf("parseMetadata() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if tt.wantErr {
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("parseMetadata() = %+v, want %+v", got, tt.want)
			}
		})
	}
}
