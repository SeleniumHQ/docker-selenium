package gridscaler

import "strings"

type Platform struct {
	name   string
	family *Platform
}

// Mapping of platform name enum used in the Selenium Grid core
// https://github.com/SeleniumHQ/selenium/blob/trunk/java/src/org/openqa/selenium/Platform.java
var (
	Windows      = Platform{"windows", nil}
	XP           = Platform{"Windows XP", &Windows}
	Vista        = Platform{"Windows Vista", &Windows}
	Win7         = Platform{"Windows 7", &Windows}
	Win8         = Platform{"Windows 8", &Windows}
	Win8_1       = Platform{"Windows 8.1", &Windows}
	Win10        = Platform{"Windows 10", &Windows}
	Win11        = Platform{"Windows 11", &Windows}
	Mac          = Platform{"mac", nil}
	SnowLeopard  = Platform{"OS X 10.6", &Mac}
	MountainLion = Platform{"OS X 10.8", &Mac}
	Mavericks    = Platform{"OS X 10.9", &Mac}
	Yosemite     = Platform{"OS X 10.10", &Mac}
	ElCapitan    = Platform{"OS X 10.11", &Mac}
	Sierra       = Platform{"macOS 10.12", &Mac}
	HighSierra   = Platform{"macOS 10.13", &Mac}
	Mojave       = Platform{"macOS 10.14", &Mac}
	Catalina     = Platform{"macOS 10.15", &Mac}
	BigSur       = Platform{"macOS 11.0", &Mac}
	Monterey     = Platform{"macOS 12.0", &Mac}
	Ventura      = Platform{"macOS 13.0", &Mac}
	Sonoma       = Platform{"macOS 14.0", &Mac}
	Sequoia      = Platform{"macOS 15.0", &Mac}
	Unix         = Platform{"unix", nil}
	Linux        = Platform{"linux", &Unix}
	Bsd          = Platform{"bsd", &Unix}
	Solaris      = Platform{"solaris", &Unix}
	Android      = Platform{"android", nil}
	IOS          = Platform{"iOS", nil}
	Any          = Platform{"any", nil}
)

func isSameFamily(p1, p2 Platform) bool {
	return p1.family != nil && p2.family != nil && p1.family == p2.family
}

func GetPlatform(input string) Platform {
	switch strings.ToLower(input) {
	case "windows":
		return Windows
	case "windows server 2003", "xp", "winnt", "windows_nt", "windows nt":
		return XP
	case "windows server 2008", "windows vista":
		return Vista
	case "windows 7", "win7":
		return Win7
	case "windows server 2012", "windows 8", "win8":
		return Win8
	case "windows 8.1", "win8.1":
		return Win8_1
	case "windows 10", "win10":
		return Win10
	case "windows 11", "win11":
		return Win11
	case "mac", "darwin", "macos", "mac os x", "os x":
		return Mac
	case "os x 10.6", "macos 10.6", "snow leopard":
		return SnowLeopard
	case "os x 10.8", "macos 10.8", "mountain lion":
		return MountainLion
	case "os x 10.9", "macos 10.9", "mavericks":
		return Mavericks
	case "os x 10.10", "macos 10.10", "yosemite":
		return Yosemite
	case "os x 10.11", "macos 10.11", "el capitan":
		return ElCapitan
	case "os x 10.12", "macos 10.12", "sierra":
		return Sierra
	case "os x 10.13", "macos 10.13", "high sierra":
		return HighSierra
	case "os x 10.14", "macos 10.14", "mojave":
		return Mojave
	case "os x 10.15", "macos 10.15", "catalina":
		return Catalina
	case "os x 11.0", "macos 11.0", "big sur":
		return BigSur
	case "os x 12.0", "macos 12.0", "monterey":
		return Monterey
	case "os x 13.0", "macos 13.0", "ventura":
		return Ventura
	case "os x 14.0", "macos 14.0", "sonoma":
		return Sonoma
	case "os x 15.0", "macos 15.0", "sequoia":
		return Sequoia
	case "linux":
		return Linux
	case "bsd":
		return Bsd
	case "solaris":
		return Solaris
	case "android", "dalvik":
		return Android
	case "ios":
		return IOS
	case "any", "":
		return Any
	default:
		return Platform{strings.ToLower(input), nil}
	}
}
