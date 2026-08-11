package gridscaler

import "testing"

// Test_GetPlatform exercises every branch of the OS/arch dispatch in
// GetPlatform, mirroring the platform-name enum used by Selenium Grid core
// (Platform.java). Inputs are matched case-insensitively, so aliases and mixed
// case must resolve to the same Platform.
func Test_GetPlatform(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  Platform
	}{
		// Windows family.
		{"windows", "windows", Windows},
		{"windows is case-insensitive", "Windows", Windows},
		{"windows server 2003 alias", "windows server 2003", XP},
		{"xp alias", "xp", XP},
		{"winnt alias", "winnt", XP},
		{"windows_nt alias", "windows_nt", XP},
		{"windows nt alias", "windows nt", XP},
		{"windows server 2008 alias", "windows server 2008", Vista},
		{"windows vista", "windows vista", Vista},
		{"windows 7", "windows 7", Win7},
		{"win7 alias", "win7", Win7},
		{"windows server 2012 alias", "windows server 2012", Win8},
		{"windows 8", "windows 8", Win8},
		{"win8 alias", "win8", Win8},
		{"windows 8.1", "windows 8.1", Win8_1},
		{"win8.1 alias", "win8.1", Win8_1},
		{"windows 10", "windows 10", Win10},
		{"win10 alias", "win10", Win10},
		{"windows 11", "windows 11", Win11},
		{"win11 alias", "win11", Win11},

		// Mac family.
		{"mac", "mac", Mac},
		{"darwin alias", "darwin", Mac},
		{"macos alias", "macos", Mac},
		{"mac os x alias", "mac os x", Mac},
		{"os x alias", "os x", Mac},
		{"snow leopard", "snow leopard", SnowLeopard},
		{"os x 10.6", "os x 10.6", SnowLeopard},
		{"mountain lion", "mountain lion", MountainLion},
		{"os x 10.8", "os x 10.8", MountainLion},
		{"mavericks", "mavericks", Mavericks},
		{"os x 10.9", "os x 10.9", Mavericks},
		{"yosemite", "yosemite", Yosemite},
		{"os x 10.10", "os x 10.10", Yosemite},
		{"el capitan", "el capitan", ElCapitan},
		{"os x 10.11", "os x 10.11", ElCapitan},
		{"sierra", "sierra", Sierra},
		{"os x 10.12", "os x 10.12", Sierra},
		{"high sierra", "high sierra", HighSierra},
		{"os x 10.13", "os x 10.13", HighSierra},
		{"mojave", "mojave", Mojave},
		{"os x 10.14", "os x 10.14", Mojave},
		{"catalina", "catalina", Catalina},
		{"os x 10.15", "os x 10.15", Catalina},
		{"big sur", "big sur", BigSur},
		{"os x 11.0", "os x 11.0", BigSur},
		{"monterey", "monterey", Monterey},
		{"os x 12.0", "os x 12.0", Monterey},
		{"ventura", "ventura", Ventura},
		{"os x 13.0", "os x 13.0", Ventura},
		{"sonoma", "sonoma", Sonoma},
		{"os x 14.0", "os x 14.0", Sonoma},
		{"sequoia", "sequoia", Sequoia},
		{"os x 15.0", "os x 15.0", Sequoia},

		// Unix family and other top-level platforms.
		{"linux", "linux", Linux},
		{"linux is case-insensitive", "Linux", Linux},
		{"bsd", "bsd", Bsd},
		{"solaris", "solaris", Solaris},
		{"android", "android", Android},
		{"dalvik alias", "dalvik", Android},
		{"ios", "ios", IOS},
		{"any", "any", Any},
		{"empty string resolves to any", "", Any},

		// Default: an unknown name is echoed back lowercased with no family.
		{"unknown name lowercased with no family", "MyCustomOS", Platform{"mycustomos", nil}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := GetPlatform(tt.input)
			if got != tt.want {
				t.Errorf("GetPlatform(%q) = %+v, want %+v", tt.input, got, tt.want)
			}
		})
	}
}
