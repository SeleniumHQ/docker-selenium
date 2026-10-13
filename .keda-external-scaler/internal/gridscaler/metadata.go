package gridscaler

import (
	"fmt"
	"strconv"
)

// Metadata is the typed form of the per-ScaledObject trigger metadata KEDA sends
// to the external scaler. It mirrors the field set of the built-in KEDA
// selenium-grid scaler so migration is mechanical.
type Metadata struct {
	URL                    string
	AuthType               string
	Username               string
	Password               string
	AccessToken            string
	BrowserName            string
	SessionBrowserName     string
	BrowserVersion         string
	PlatformName           string
	ActivationThreshold    int64
	UnsafeSsl              bool
	NodeMaxSessions        int64
	EnableManagedDownloads bool
	Capabilities           string
	IncludeOngoingSessions bool

	TargetValue int64
}

// envFallbacks maps a base metadata key to the server-side environment variable
// consulted when neither <key> nor <key>FromEnv is present in scalerMetadata.
// This exists because KEDA does not forward TriggerAuthentication authParams to
// external scalers, so Grid URL and credentials may instead be mounted into the
// scaler process environment.
var envFallbacks = map[string]string{
	"url":         "SE_GRID_URL",
	"authType":    "SE_GRID_AUTH_TYPE",
	"username":    "SE_USERNAME",
	"password":    "SE_PASSWORD",
	"accessToken": "SE_ACCESS_TOKEN",
}

// parseMetadata builds a Metadata from the scalerMetadata map KEDA sends and the
// scaler's own environment (env). Per-key resolution precedence is:
//
//	scalerMetadata[<name>] > scalerMetadata[<name>FromEnv] > env[<fallback>]
//
// KEDA resolves *FromEnv keys against the scale target's container environment
// before sending, storing the resolved value under the original *FromEnv key, so
// scalerMetadata["usernameFromEnv"] already holds the secret value here.
func parseMetadata(scalerMetadata map[string]string, env map[string]string) (*Metadata, error) {
	if scalerMetadata == nil {
		scalerMetadata = map[string]string{}
	}
	if env == nil {
		env = map[string]string{}
	}

	lookup := func(key string) string {
		if v, ok := scalerMetadata[key]; ok {
			return v
		}
		if v, ok := scalerMetadata[key+"FromEnv"]; ok {
			return v
		}
		if envKey, ok := envFallbacks[key]; ok {
			if v := env[envKey]; v != "" {
				return v
			}
		}
		return ""
	}

	meta := &Metadata{
		TargetValue:            1,
		NodeMaxSessions:        1,
		EnableManagedDownloads: true,
		IncludeOngoingSessions: true,
	}

	meta.URL = lookup("url")
	if meta.URL == "" {
		return nil, fmt.Errorf("no url given in trigger metadata, FromEnv, or scaler environment (%s)", envFallbacks["url"])
	}

	meta.AuthType = lookup("authType")
	meta.Username = lookup("username")
	meta.Password = lookup("password")
	meta.AccessToken = lookup("accessToken")
	meta.BrowserName = lookup("browserName")
	meta.SessionBrowserName = lookup("sessionBrowserName")
	meta.BrowserVersion = lookup("browserVersion")
	meta.PlatformName = lookup("platformName")
	meta.Capabilities = lookup("capabilities")

	if v := lookup("activationThreshold"); v != "" {
		n, err := strconv.ParseInt(v, 10, 64)
		if err != nil {
			return nil, fmt.Errorf("parsing activationThreshold: %w", err)
		}
		meta.ActivationThreshold = n
	}

	if v := lookup("nodeMaxSessions"); v != "" {
		n, err := strconv.ParseInt(v, 10, 64)
		if err != nil {
			return nil, fmt.Errorf("parsing nodeMaxSessions: %w", err)
		}
		meta.NodeMaxSessions = n
	}

	if v := lookup("unsafeSsl"); v != "" {
		b, err := strconv.ParseBool(v)
		if err != nil {
			return nil, fmt.Errorf("parsing unsafeSsl: %w", err)
		}
		meta.UnsafeSsl = b
	}

	if v := lookup("enableManagedDownloads"); v != "" {
		b, err := strconv.ParseBool(v)
		if err != nil {
			return nil, fmt.Errorf("parsing enableManagedDownloads: %w", err)
		}
		meta.EnableManagedDownloads = b
	}

	if v := lookup("includeOngoingSessions"); v != "" {
		b, err := strconv.ParseBool(v)
		if err != nil {
			return nil, fmt.Errorf("parsing includeOngoingSessions: %w", err)
		}
		meta.IncludeOngoingSessions = b
	}

	if meta.SessionBrowserName == "" {
		meta.SessionBrowserName = meta.BrowserName
	}

	return meta, nil
}
