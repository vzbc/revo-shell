.pragma library

// Generic settings content: blocks -> { header?, note?, rows: [...] }
// row: { t, s?, i?, v?, c?, to?, sw?, on?, red?, dim?, info? }
var content = {
    // ============ Apple Account ============
    "acct.personalInfo": [
        { rows: [
            { t: "Name", v: "{name}", to: "acct.personalInfo.name" },
            { t: "Phone Numbers", v: "Add", to: "acct.personalInfo.phone" },
            { t: "Email", v: "{email}", to: "acct.personalInfo.email" },
            { t: "Country / Region", v: "{country}", to: "acct.personalInfo.country" },
            { t: "Date of Birth", to: "acct.personalInfo.birth" }
        ] },
        { header: "Family Sharing", rows: [
            { t: "My Info", v: "{name}", to: "acct.personalInfo.myInfo" }
        ] }
    ],
    "acct.personalInfo.name": [ { rows: [ { t: "First Name", v: "{name}" }, { t: "Last Name" } ] } ],
    "acct.personalInfo.phone": [ { rows: [ { t: "Add Phone Number…", red2: true } ], note: "Verified phone numbers can be used to sign in, reset your password, and recover your account." } ],
    "acct.personalInfo.email": [ { rows: [ { t: "{email}", s: "Primary" } ] } ],
    "acct.personalInfo.country": [ { rows: [ { t: "Country or Region", v: "{country}" }, { t: "Language", v: "{lang}" } ], note: "Detected from this Mac\u2019s system region settings." } ],
    "acct.personalInfo.birth": [ { rows: [ { t: "Day" }, { t: "Month" }, { t: "Year" } ] } ],
    "acct.personalInfo.myInfo": [ { rows: [ { t: "Name", v: "{name}" }, { t: "Email", v: "{email}" } ] } ],

    "acct.security": [
        { rows: [
            { t: "Sign-In & Security", dim: true },
            { t: "Email", v: "{email}", to: "acct.personalInfo.email" },
            { t: "Phone Numbers", to: "acct.personalInfo.phone" },
            { t: "Apple Account Password", to: "acct.security.password" }
        ] },
        { header: "Sign-In Options", rows: [
            { t: "Two-Factor Authentication", v: "On", to: "acct.security.twoFactor" },
            { t: "Passkeys", to: "acct.security.passkeys" },
            { t: "Recovery Contacts", v: "None", to: "acct.security.recovery" },
            { t: "Recovery Key", v: "Not Created", to: "acct.security.recoveryKey" }
        ] },
        { header: "Account Recovery", rows: [
            { t: "Legacy Contacts", v: "None", ecfg: "account.legacyContact", def: "None" }
        ] }
    ],
    "acct.security.password": [ { rows: [ { t: "Change Password…", c: true, cmd: "kitty --title 'Change Password' -e passwd" } ], note: "Your password is used to sign in to your Apple Account." } ],
    "acct.security.twoFactor": [ { rows: [ { t: "Two-Factor Authentication", ecfg: "account.twoFactor", def: true, sw: true } ], note: "Two-factor authentication protects your Apple Account by requiring a verification code when you sign in on a new device." } ],
    "acct.security.passkeys": [ { rows: [ { t: "iCloud Keychain", ecfg: "account.keychain", def: true, sw: true }, { t: "Passkeys", c: true } ] } ],
    "acct.security.recovery": [ { rows: [ { t: "Add Recovery Contact…", cmd: "sh -c 'notify-send \"Recovery Contact\" \"Open iCloud.com to add a recovery contact.\"'" } ] } ],
    "acct.security.recoveryKey": [ { rows: [ { t: "Create Recovery Key…", cmd: "sh -c 'head -c 16 /dev/urandom | base64 | xclip -selection clipboard && notify-send \"Recovery Key\" \"A 16-byte recovery key was copied to the clipboard.\"'" } ] } ],

    "acct.payment": [
        { rows: [
            { t: "Payment Methods", to: "acct.payment.methods" },
            { t: "Shipping Address", to: "acct.payment.shipping" }
        ] },
        { header: "Subscriptions", rows: [
            { t: "Manage Subscriptions", to: "acct.payment.subs" }
        ] },
        { header: "Orders", rows: [
            { t: "View Purchase History", to: "acct.payment.orders" }
        ] }
    ],
    "acct.payment.methods": [ { rows: [ { t: "Add Payment Method…", cmd: "sh -c 'notify-send \"Wallet\" \"Add a card in System Settings > Wallet & Apple Pay.\"'" } ] } ],
    "acct.payment.shipping": [ { rows: [ { t: "Name", v: "{name}" }, { t: "Street", v: "Add Address" } ] } ],
    "acct.payment.subs": [ { rows: [ { t: "No Active Subscriptions", dim: true } ] } ],
    "acct.payment.orders": [ { rows: [ { t: "No Past Orders", dim: true } ] } ],

    "acct.media": [
        { rows: [
            { t: "Subscriptions", to: "acct.payment.subs" },
            { t: "Purchase History", to: "acct.payment.orders" }
        ] },
        { header: "Apps & Media", rows: [
            { t: "Automatic Downloads", ecfg: "media.autoDownloads", def: true, sw: true },
            { t: "Offload Unused Apps", ecfg: "media.offload", def: true, sw: true }
        ] }
    ],

    "acct.family": [
        { rows: [
            { t: "Family", s: "Share subscriptions, iCloud+, and more with up to five people.", to: "acct.family.members" }
        ] },
        { header: "Family Sharing", rows: [
            { t: "Location Sharing", ecfg: "family.locationSharing", def: true, sw: true },
            { t: "Ask to Buy", ecfg: "family.askToBuy", def: true, sw: true },
            { t: "Screen Time", ecfg: "family.screenTime", def: false, sw: true }
        ] },
        { header: "Shared", rows: [
            { t: "iCloud+", to: "icloud" },
            { t: "Subscriptions", to: "acct.payment.subs" },
            { t: "Purchase Sharing", ecfg: "family.purchaseSharing", def: true, sw: true }
        ] }
    ],
    "acct.family.members": [ { rows: [ { t: "{name}", s: "You (Organizer)" }, { t: "Add Member…" } ] } ],

    "acct.findMy": [
        { rows: [
            { t: "Find My Mac", ecfg: "findmy.mac", def: true, sw: true },
            { t: "Find My Network", ecfg: "findmy.network", def: true, sw: true }
        ] },
        { header: "Location Sharing", rows: [
            { t: "Share My Location", ecfg: "findmy.shareLocation", def: true, sw: true },
            { t: "From", v: "This Mac" }
        ] },
        { header: "Devices", rows: [
            { t: "This Mac", s: "Online", to: "acct.deviceDetails" }
        ] }
    ],

    "acct.signinWithApple": [
        { rows: [
            { t: "Apps Using Sign in with Apple", dim: true },
            { t: "No Apps", dim: true }
        ] },
        { note: "Sign in with Apple lets you sign in to apps and websites using your Apple Account." }
    ],

    "acct.deviceDetails": [
        { rows: [
            { t: "Device Name", v: "{host}" },
            { t: "Model", v: "{model}" },
            { t: "Version", v: "{os}" },
            { t: "Serial Number", v: "{serial}" },
            { t: "Chip", v: "{cpu}" },
            { t: "Memory", v: "{ram}" },
            { t: "Storage", v: "{storage}" },
            { t: "IP Address", v: "{ip}" },
            { t: "Uptime", v: "{uptime}" }
        ] },
        { header: "Find My", rows: [
            { t: "Find My Mac", ecfg: "findmy.mac", def: true, sw: true }
        ] }
    ],

    // ============ General ============
    "gen.about": [
        { rows: [
            { t: "Name", v: "{name}'s Mac Pro", to: "gen.about.name" },
            { t: "Chip", v: "Apple M4 Max" },
            { t: "Memory", v: "64 GB" },
            { t: "Serial Number", v: "C02XK1ABCDEFG" },
            { t: "macOS", v: "Tahoe 26.1", to: "gen.about.version" }
        ] },
        { rows: [
            { t: "Storage", v: "{storage}", to: "gen.storage" },
            { t: "Coverage", v: "Limited Coverage", to: "gen.appleCare" }
        ] },
        { rows: [
            { t: "System Report…", c: true },
            { t: "Regulatory Certification…", c: true }
        ] }
    ],
    "gen.about.name": [ { rows: [ { t: "Computer Name", v: "{name}'s Mac Pro" } ] } ],
    "gen.about.version": [
        { rows: [
            { t: "macOS Tahoe", v: "26.1" },
            { t: "Build", v: "25B78" }
        ] },
        { note: "macOS Tahoe brings a new Liquid Glass design, Live Activities, and more." }
    ],

    "gen.softwareUpdate": [
        { rows: [
            { t: "Automatic Updates", to: "gen.softwareUpdate.auto" },
            { t: "Check for Updates", c: true },
            { t: "Update Now", c: true },
            { t: "Upgrade Now", c: true }
        ] },
        { note: "macOS Tahoe 26.1 is available. Your Mac is up to date." }
    ],
    "gen.softwareUpdate.auto": [
        { header: "Automatically", rows: [
            { t: "Check for updates", sw: true, on: true },
            { t: "Download new updates when available", sw: true, on: true },
            { t: "Install macOS updates", sw: true, on: true },
            { t: "Install application updates from the App Store", sw: true, on: true },
            { t: "Install Security Responses and system files", sw: true, on: true }
        ] },
        { note: "Updates require your Mac to be connected to power." }
    ],

    "gen.storage": [
        { rows: [
            { t: "Applications", v: "48.2 GB", to: "gen.storage.apps" },
            { t: "Documents", v: "214 GB", to: "gen.storage.docs" },
            { t: "macOS", v: "24.6 GB" },
            { t: "System Data", v: "86.4 GB", to: "gen.storage.system" },
            { t: "Bins", v: "1.4 GB", c: true }
        ] },
        { header: "Recommendations", rows: [
            { t: "Store in iCloud", c: true },
            { t: "Optimize Storage", c: true },
            { t: "Empty Bins Automatically", sw: true, on: false }
        ] }
    ],

    "gen.appleCare": [
        { rows: [
            { t: "Limited Coverage", s: "Expires October 14, 2026", to: "gen.appleCare.details" },
            { t: "Check Coverage…", c: true }
        ] },
        { note: "Your Mac is covered by AppleCare limited warranty." }
    ],
    "gen.appleCare.details": [ { rows: [ { t: "Purchase AppleCare+", c: true }, { t: "Service and Repair", c: true } ] } ],

    "gen.airDrop": [
        { header: "AirDrop", rows: [
            { t: "Allow me to be discovered by", v: "Contacts Only" },
            { t: "Everyone for 10 Minutes", c: true }
        ] },
        { header: "Handoff", rows: [
            { t: "Handoff between this Mac and your iCloud devices", sw: true, on: true }
        ] },
        { note: "Handoff lets you start a task on one device and pick it up on another." }
    ],

    "gen.autoFill": [
        { header: "AutoFill & Passwords", rows: [
            { t: "AutoFill Passwords and Passkeys", sw: true, on: true },
            { t: "AutoFill from Contacts", sw: true, on: false },
            { t: "AutoFill Verification Codes", sw: true, on: true }
        ] },
        { header: "Passwords", rows: [
            { t: "Deleted Passwords", v: "None", c: true }
        ] },
        { header: "Verification Codes", rows: [
            { t: "Delete After", v: "Never" }
        ] }
    ],

    "gen.dateAndTime": [
        { rows: [
            { t: "Set date and time automatically", sw: true, on: true },
            { t: "Date & Time", v: "Today, 21:30" },
            { t: "Time zone", v: "Automatic", sw: true, on: true },
            { t: "Closest City", v: "Riyadh" }
        ] }
    ],

    "gen.language": [
        { rows: [
            { t: "Languages", v: "English (US)", to: "gen.language.list" },
            { t: "Region", v: "United States", to: "gen.language.region" },
            { t: "Calendar", v: "Gregorian" },
            { t: "Temperature", v: "Celsius" },
            { t: "First Day of Week", v: "Sunday" }
        ] }
    ],
    "gen.language.list": [ { rows: [ { t: "English (US)", s: "Primary" }, { t: "Arabic", c: true }, { t: "Add Language…", c: true } ] } ],
    "gen.language.region": [ { rows: [ { t: "United States", s: "Primary" }, { t: "Saudi Arabia", c: true } ] } ],

    "gen.loginItems": [
        { header: "Open at Login", rows: [
            { t: "None", dim: true }
        ] },
        { header: "Allow in the Background", note: "These items will be allowed to run in the background.", rows: [
            { t: "Cloud", sw: true, on: true },
            { t: "Software Update", sw: true, on: true },
            { t: "Spotlight", sw: true, on: true }
        ] },
        { header: "Extensions", rows: [
            { t: "Added Extensions", c: true },
            { t: "Sharing", c: true },
            { t: "Photos", c: true }
        ] }
    ],

    "gen.sharing": [
        { rows: [
            { t: "Screen Sharing", sw: false, on: false },
            { t: "File Sharing", sw: false, on: false },
            { t: "Media Sharing", sw: false, on: false },
            { t: "Printer Sharing", sw: false, on: false },
            { t: "Remote Login", sw: false, on: false },
            { t: "Remote Management", sw: false, on: false },
            { t: "Remote Apple Events", sw: false, on: false },
            { t: "Internet Sharing", sw: false, on: false }
        ] },
        { rows: [
            { t: "Computer Name", v: "{name}'s Mac Pro", to: "gen.about.name" },
            { t: "Local Hostname", v: "mac.local" }
        ] }
    ],

    "gen.startupDisk": [
        { rows: [
            { t: "Macintosh HD", s: "macOS Tahoe 26.1", c: true },
            { t: "Network Startup Disk", dim: true }
        ] },
        { rows: [
            { t: "Set as default startup disk", sw: true, on: true },
            { t: "Show all volumes", sw: false, on: false }
        ] }
    ],

    "gen.timeMachine": [
        { rows: [
            { t: "Back up automatically", sw: true, on: true },
            { t: "Back up using Time Machine", v: "Off", to: "gen.timeMachine.select" },
            { t: "Show Time Machine in menu bar", sw: false, on: false }
        ] },
        { rows: [
            { t: "Old Backups", c: true },
            { t: "Manage Backups…", c: true }
        ] },
        { note: "Time Machine backs up your files so you can restore them later." }
    ],
    "gen.timeMachine.select": [ { rows: [ { t: "Select Backup Disk…" }, { t: "Back Up Disk", v: "None" } ] } ],

    "gen.deviceManagement": [
        { rows: [
            { t: "No profiles installed", dim: true }
        ] },
        { note: "Mobile configuration profiles and device management settings appear here." }
    ],

    "gen.transfer": [
        { rows: [
            { t: "Open Migration Assistant", c: true },
            { t: "Erase All Content and Settings…", red: true, c: true }
        ] },
        { note: "Migration Assistant copies your files from another Mac or PC." }
    ],

    // ============ Wi-Fi ============
    "wifi.details": [
        { rows: [
            { t: "Network Name", v: "Home_5G" },
            { t: "IP Address", v: "192.168.1.24" },
            { t: "Router", v: "192.168.1.1" },
            { t: "Subnet Mask", v: "255.255.255.0" },
            { t: "DNS", v: "1.1.1.1" }
        ] },
        { header: "Hardware", rows: [
            { t: "Security", v: "WPA3 Personal" },
            { t: "Channel", v: "149 (5 GHz, 80 MHz)" },
            { t: "PHY Mode", v: "802.11ax" },
            { t: "BSSID", v: "a4:83:e7:11:22:33" },
            { t: "RSSI", v: "-52 dBm" }
        ] },
        { header: "Options", rows: [
            { t: "Ask to join networks", v: "Notify" },
            { t: "Ask to join hotspots", v: "Ask to Join" },
            { t: "Limit IP address tracking", sw: true, on: true },
            { t: "Auto-join", sw: true, on: true }
        ] }
    ],

    // ============ Accessibility ============
    "acc.voiceOver": [
        { rows: [
            { t: "VoiceOver", sw: false, on: false },
            { t: "Open VoiceOver Utility…", c: true }
        ] },
        { header: "Quick Start", rows: [
            { t: "Welcome Window", c: true }
        ] },
        { note: "VoiceOver speaks items on the screen so you can use your Mac without a display." }
    ],
    "acc.zoom": [
        { rows: [
            { t: "Use keyboard shortcuts to zoom", sw: true, on: true },
            { t: "Use scroll gesture with modifier keys to zoom", sw: false, on: false },
            { t: "Hover Text", sw: false, on: false, to: "acc.hoverText" }
        ] },
        { header: "Zoom Style", rows: [
            { t: "Fullscreen Zoom", sw: false, on: true },
            { t: "Split Screen Zoom", sw: false, on: false }
        ] },
        { header: "Options", rows: [
            { t: "Zoom in", v: "⌥⌘=" },
            { t: "Zoom out", v: "⌥⌘−" },
            { t: "Move image", v: "⌥⌘8" }
        ] }
    ],
    "acc.display": [
        { header: "Vision", rows: [
            { t: "Invert Colours", sw: false, on: false },
            { t: "Reduce Transparency", sw: false, on: false },
            { t: "Increase Contrast", sw: false, on: false },
            { t: "Differentiate without Colour", sw: false, on: false }
        ] },
        { header: "Cursor", rows: [
            { t: "Shake mouse pointer to locate", sw: true, on: true },
            { t: "Pointer size", v: "Default" }
        ] },
        { header: "Display", rows: [
            { t: "Reduce motion", sw: false, on: false, to: "acc.motion" },
            { t: "Dim flashing lights", sw: false, on: false, to: "acc.motion" }
        ] }
    ],
    "acc.readSpeak": [
        { header: "Spoken Content", rows: [
            { t: "Speak selection", sw: false, on: false },
            { t: "Speak items under pointer", sw: false, on: false },
            { t: "Highlight content", v: "Off" },
            { t: "Verbosity", v: "Normal" }
        ] },
        { header: "System Voice", rows: [
            { t: "Voice", v: "Samantha (Enhanced)" },
            { t: "Speaking Rate", v: "Default" }
        ] }
    ],
    "acc.audioDescriptions": [
        { rows: [ { t: "Prefer audio descriptions", sw: false, on: false } ] },
        { note: "Audio descriptions describe visual content in supported videos." }
    ],
    "acc.hearingDevices": [
        { rows: [ { t: "Bluetooth", v: "Searching…" }, { t: "MFi Hearing Devices", dim: true } ] },
        { note: "Hearing devices paired with your Mac appear here." }
    ],
    "acc.hearingAudio": [
        { header: "Audio", rows: [
            { t: "Mono audio", sw: false, on: false },
            { t: "Balance", v: "Center" },
            { t: "Play stereo audio as mono", sw: false, on: false }
        ] },
        { header: "Alerts", rows: [
            { t: "Flash the screen when an alert sound occurs", sw: false, on: false },
            { t: "Play sound effects through", v: "System Output" }
        ] }
    ],
    "acc.rtt": [
        { rows: [ { t: "RTT", sw: false, on: false }, { t: "TTY", sw: false, on: false } ] },
        { note: "Real-Time Text lets you send text as you type." }
    ],
    "acc.voiceControl": [
        { rows: [
            { t: "Voice Control", sw: false, on: false },
            { t: "Language", v: "English (United States)" },
            { t: "Commands…", c: true }
        ] }
    ],
    "acc.pointerControl": [
        { header: "Mouse & Trackpad", rows: [
            { t: "Double-click speed", v: "Normal" },
            { t: "Spring-loading delay", v: "Normal" },
            { t: "Tracking speed", v: "Normal" }
        ] },
        { header: "Alternative Control Methods", rows: [
            { t: "Mouse Keys", sw: false, on: false },
            { t: "Keyboard Shortcuts", c: true },
            { t: "Switch Control", sw: false, on: false, to: "acc.switchControl" }
        ] }
    ],
    "acc.switchControl": [
        { rows: [
            { t: "Switch Control", sw: false, on: false },
            { t: "Scanning", v: "Linear" },
            { t: "Switches…", c: true }
        ] }
    ],

    // ============ Privacy & Security ============
    "privacy.locationServices": [
        { rows: [
            { t: "Location Services", sw: true, on: true },
            { t: "Safari", sw: true, on: true },
            { t: "Maps", sw: true, on: true },
            { t: "Find My", sw: true, on: true, to: "acct.findMy" },
            { t: "System Services", c: true }
        ] },
        { note: "Location Services uses your location to improve features such as Maps and Siri." }
    ],
    "privacy.contacts": [ { rows: [ { t: "Calendar", sw: true, on: true }, { t: "Safari", sw: false, on: false }, { t: "Mail", sw: true, on: true } ] } ],
    "privacy.calendars": [ { rows: [ { t: "Safari", sw: true, on: true }, { t: "Reminders", sw: true, on: true } ] } ],
    "privacy.reminders": [ { rows: [ { t: "Safari", sw: false, on: false } ] } ],
    "privacy.photos": [ { rows: [ { t: "Preview", sw: true, on: true }, { t: "Safari", sw: false, on: false } ] } ],
    "privacy.bluetooth": [ { rows: [ { t: "Bluetooth Apps", dim: true }, { t: "System Settings", sw: true, on: true } ] } ],
    "privacy.microphone": [ { rows: [ { t: "FaceTime", sw: true, on: true }, { t: "Zoom", sw: false, on: false } ] } ],
    "privacy.camera": [ { rows: [ { t: "FaceTime", sw: true, on: true }, { t: "Photo Booth", sw: false, on: false } ] } ],
    "privacy.screenRecording": [ { rows: [ { t: "Screenshot", sw: true, on: true }, { t: "Zoom", sw: false, on: false } ], note: "Apps with screen recording access can record your screen and audio." } ],
    "privacy.focus": [ { rows: [ { t: "No apps allowed", dim: true } ] } ],
    "privacy.audioInput": [ { rows: [ { t: "Voice Memos", sw: true, on: true }, { t: "Safari", sw: false, on: false } ] } ],
    "privacy.fullDiskAccess": [ { rows: [ { t: "No apps have full disk access", dim: true } ], note: "Apps with full disk access can access files on your Mac, including mail, messages, and Safari data." } ],
    "privacy.filesFolders": [ { rows: [ { t: "Desktop Folder", dim: true }, { t: "Documents Folder", dim: true } ] } ],
    "privacy.devTools": [ { rows: [ { t: "No apps", dim: true } ] } ],
    "privacy.analytics": [
        { rows: [
            { t: "Share Mac Analytics", sw: true, on: true },
            { t: "Share iCloud Analytics", sw: false, on: false },
            { t: "Improve Siri", sw: true, on: true },
            { t: "Share with App Developers", sw: false, on: false }
        ] }
    ],
    "privacy.advertising": [
        { rows: [
            { t: "Personalised Ads", sw: false, on: false },
            { t: "Reset Advertising Identifier…", c: true }
        ] },
        { note: "The Apple Advertising platform does not track you across companies' apps and websites." }
    ],

    // ============ Sound ============
    "sound.effects": [
        { header: "Alert Sound", rows: [
            { t: "Alert sound", v: "Boop" },
            { t: "Play sound effects through", v: "System Output" },
            { t: "Alert volume", v: "50%" }
        ] },
        { header: "Output Volume", rows: [
            { t: "Show Sound in menu bar", v: "Always" },
            { t: "Play feedback when volume is changed", sw: false, on: false },
            { t: "Play UI sound effects", sw: true, on: true }
        ] }
    ],
    "sound.output": [
        { rows: [
            { t: "Mac Pro Speakers", s: "Built-in", c: true },
            { t: "External Headphones", dim: true }
        ] },
        { header: "Output", rows: [
            { t: "Balance", v: "Center" },
            { t: "Show volume in menu bar", sw: true, on: true }
        ] }
    ],
    "sound.input": [
        { rows: [
            { t: "Mac Pro Microphone", s: "Built-in", c: true },
            { t: "External Microphone", dim: true }
        ] },
        { header: "Input", rows: [
            { t: "Input volume", v: "60%" },
            { t: "Input monitor", v: "0%" }
        ] }
    ],

    // ============ Spotlight ============
    "spotlight.privacy": [
        { rows: [ { t: "macOS", dim: true }, { t: "Applications", dim: true }, { t: "Documents", dim: true } ] },
        { rows: [ { t: "Add…", c: true }, { t: "Remove", c: true } ] }
    ],

    // ============ Desktop & Dock ============
    "desktopDock.displays": [
        { rows: [
            { t: "Show items on desktop", sw: true, on: true },
            { t: "Click wallpaper to reveal desktop", v: "Only in Stage Manager" }
        ] }
    ],
    "desktopDock.stageManager": [
        { rows: [
            { t: "Stage Manager", sw: false, on: false },
            { t: "Show recent applications in Stage Manager", sw: true, on: true }
        ] }
    ],

    // ============ Displays ============
    "displays.nightShift": [
        { rows: [
            { t: "Night Shift", sw: false, on: false },
            { t: "Schedule", v: "Sunset to Sunrise" },
            { t: "Colour temperature", v: "Normal" }
        ] }
    ],
    "displays.trueTone": [ { rows: [ { t: "True Tone", sw: true, on: true } ], note: "True Tone automatically adapts display colour to make images appear more natural." } ],

    // ============ Wallpaper ============
    "wallpaper.dynamic": [
        { rows: [
            { t: "Dynamic Desktop", sw: true, on: true },
            { t: "Show on all Spaces", sw: true, on: true },
            { t: "Show wallpaper picture in Stage Manager", sw: true, on: true }
        ] }
    ],

    // ============ Notifications ============
    "notifications.appSettings": [
        { rows: [
            { t: "Allow notifications", sw: true, on: true },
            { t: "Show previews", v: "When Unlocked" },
            { t: "Play sound", sw: true, on: true },
            { t: "Badges", sw: true, on: true },
            { t: "Show in Notification Centre", sw: true, on: true },
            { t: "Allow time sensitive", sw: true, on: true }
        ] }
    ],
    "notifications.focus": [
        { rows: [
            { t: "Deliver notifications", v: "Immediately" },
            { t: "Automatically silence", sw: true, on: false },
            { t: "Time sensitive notifications", sw: true, on: true }
        ] }
    ],
    "notifications.summaries": [
        { rows: [
            { t: "Summarise notifications", sw: true, on: true },
            { t: "Scheduled Summary", sw: true, on: true },
            { t: "Time", v: "08:00, 12:00, 18:00" }
        ] }
    ],

    // ============ Focus ============
    "focus.iCloud": [ { rows: [ { t: "Share across devices", sw: true, on: true } ] } ],
    "focus.schedules": [ { rows: [ { t: "Add Schedule…", c: true } ], note: "Schedules turn Focus on automatically based on time, location, or app usage." } ],
    "focus.filters": [ { rows: [ { t: "Home Screen", sw: false, on: false }, { t: "Lock Screen", sw: true, on: true } ] } ],

    // ============ Screen Time ============
    "screenTime.downtime": [
        { rows: [
            { t: "Downtime", sw: false, on: false },
            { t: "Schedule", v: "Every Day" },
            { t: "Start", v: "22:00" },
            { t: "End", v: "07:00" }
        ] }
    ],
    "screenTime.appLimits": [ { rows: [ { t: "Add Limit…", c: true } ], note: "App Limits let you set time limits for categories of apps." } ],
    "screenTime.alwaysAllowed": [ { rows: [ { t: "Phone", s: "Always Allowed" }, { t: "Messages", s: "Always Allowed" } ] } ],
    "screenTime.contentPrivacy": [
        { header: "Content & Privacy", rows: [
            { t: "Content & Privacy Restrictions", sw: false, on: false },
            { t: "Store Web Content", v: "Allowed" },
            { t: "Allowed Apps", c: true }
        ] }
    ],
    "screenTime.viewReports": [ { rows: [ { t: "Share across devices", sw: true, on: true } ] } ],

    // ============ Lock Screen ============
    "lockScreen.requirePassword": [
        { rows: [
            { t: "Require password after screen saver begins", v: "Immediately" },
            { t: "Start Screen Saver when inactive", v: "20 minutes" }
        ] }
    ],
    "lockScreen.notifications": [
        { rows: [
            { t: "Show notifications when locked", sw: true, on: true },
            { t: "Show previews", v: "When Unlocked" },
            { t: "Show Passpoint cards", sw: false, on: false },
            { t: "Show Quick Notes", sw: true, on: true },
            { t: "Show widgets", sw: true, on: true }
        ] }
    ],

    // ============ Touch ID & Password ============
    "touchID.fingerprint": [
        { rows: [
            { t: "Unlocking your Mac", sw: true, on: true },
            { t: "Apple Pay", sw: true, on: true },
            { t: "iTunes Store, App Store & Apple Books", sw: true, on: true },
            { t: "Password autofill", sw: true, on: true },
            { t: "Apple Cash & Cards in Wallet", sw: true, on: false }
        ] },
        { note: "Touch ID lets you unlock your Mac and authorise purchases with your fingerprint." }
    ],
    "touchID.password": [
        { rows: [
            { t: "Change Password…", c: true },
            { t: "Reset Password with Recovery Key…", c: true }
        ] },
        { header: "Options", rows: [
            { t: "Require password to wake from screen saver", sw: true, on: true },
            { t: "Automatically log out after inactivity", sw: false, on: false }
        ] }
    ],

    // ============ Users & Groups ============
    "users.edit": [
        { rows: [
            { t: "Full Name", v: "{name}" },
            { t: "Account Name", v: "user" },
            { t: "Password", v: "••••••••", to: "touchID.password" },
            { t: "Profile Picture", c: true }
        ] },
        { header: "Role", rows: [
            { t: "Administrator", sw: true, on: true },
            { t: "Allow user to administer this computer", sw: true, on: true }
        ] }
    ],
    "users.guest": [ { rows: [ { t: "Guest User", sw: false, on: false }, { t: "Allow guests to log in to this computer", sw: false, on: false } ] } ],
    "users.autoLogin": [ { rows: [ { t: "Automatically log in as", v: "Off" } ] } ],

    // ============ Internet Accounts ============
    "internetAccounts.add": [
        { rows: [
            { t: "iCloud", c: true },
            { t: "Microsoft Exchange", c: true },
            { t: "Google", c: true },
            { t: "Yahoo", c: true },
            { t: "Add Other Account…", c: true }
        ] }
    ],

    // ============ Game Center ============
    "gameCenter.profile": [
        { rows: [
            { t: "Nickname", v: "{name}" },
            { t: "Profile Privacy", v: "Friends" },
            { t: "Avatar", c: true }
        ] }
    ],
    "gameCenter.friends": [ { rows: [ { t: "No friends yet", dim: true }, { t: "Add Friends…", c: true } ] } ],

    // ============ iCloud ============
    "icloud.storage": [
        { rows: [
            { t: "5 GB of 5 GB used", dim: true },
            { t: "Manage…", c: true },
            { t: "Change Storage Plan…", c: true }
        ] },
        { header: "Apps using iCloud", rows: [
            { t: "iCloud Drive", sw: true, on: true },
            { t: "Photos", sw: true, on: true },
            { t: "Mail", sw: true, on: false },
            { t: "Notes", sw: true, on: true },
            { t: "Passwords", sw: true, on: true },
            { t: "Find My Mac", sw: true, on: true, to: "acct.findMy" }
        ] }
    ],
    "icloud.privateRelay": [ { rows: [ { t: "iCloud Private Relay", sw: true, on: true }, { t: "IP Address Location", v: "Country & Time Zone" } ] } ],
    "icloud.hideMyEmail": [ { rows: [ { t: "Hide My Email", c: true } ], note: "Create unique, random email addresses that forward to your personal inbox." } ],
    "icloud.family": [ { rows: [ { t: "Manage Family…", c: true } ] } ],

    // ============ Keyboard ============
    "keyboard.input": [
        { header: "Key Repeat", rows: [
            { t: "Key repeat rate", v: "Fast" },
            { t: "Delay until repeat", v: "Short" }
        ] },
        { header: "Keyboard Shortcuts", rows: [
            { t: "Keyboard Shortcuts…", c: true },
            { t: "Modifier keys…", c: true }
        ] }
    ],
    "keyboard.dictation": [ { rows: [ { t: "Dictation", sw: false, on: false }, { t: "Shortcut", v: "Press 🌐 twice" } ] } ],
    "keyboard.textReplacements": [ { rows: [ { t: "Add…", c: true }, { t: "omw → On my way!", c: true } ] } ],
    "keyboard.hardware": [
        { rows: [
            { t: "Adjust keyboard brightness in low light", sw: true, on: true },
            { t: "Turn keyboard backlight off after inactivity", v: "5 seconds" },
            { t: "Press 🌐 to change input source", sw: true, on: true },
            { t: "Use F1, F2, etc. keys as standard function keys", sw: false, on: false }
        ] }
    ],

    // ============ Trackpad ============
    "trackpad.pointClick": [
        { header: "Point & Click", rows: [
            { t: "Tracking speed", v: "Normal" },
            { t: "Force Click and haptic feedback", sw: true, on: true },
            { t: "Silent clicking", sw: false, on: false },
            { t: "Look up & data detectors", v: "Force Click with One Finger" },
            { t: "Secondary click", v: "Click or Tap with Two Fingers" },
            { t: "Tap to click", sw: true, on: true }
        ] }
    ],
    "trackpad.scrollZoom": [
        { header: "Scroll & Zoom", rows: [
            { t: "Scroll direction: Natural", sw: true, on: true },
            { t: "Zoom in or out", v: "Scroll with Two Fingers" },
            { t: "Smart zoom", v: "Double-Tap with Two Fingers" },
            { t: "Rotate", v: "Rotate with Two Fingers" }
        ] }
    ],
    "trackpad.moreGestures": [
        { header: "More Gestures", rows: [
            { t: "Swipe between pages", v: "Scroll Left or Right with Two Fingers" },
            { t: "Swipe between full-screen apps", v: "Swipe with Three Fingers" },
            { t: "Notification Centre", v: "Swipe Left with Two Fingers" },
            { t: "Mission Control", v: "Swipe Up with Three Fingers" },
            { t: "Launchpad", v: "Pinch with Thumb and Three Fingers" },
            { t: "App Exposé", v: "Swipe Down with Three Fingers" }
        ] }
    ],

    // ============ Printers & Scanners ============
    "printers.add": [
        { rows: [ { t: "Add Printer, Scanner or Fax…", c: true } ] },
        { note: "Printers on your network appear here automatically." }
    ],
    "printers.options": [ { rows: [ { t: "Default printer", v: "Last Printer Used" }, { t: "Default paper size", v: "A4" } ] } ]
}

// Titles for toolbar (fallback when not in Pages.info)
var titles = {
    "acct.personalInfo.name": "Name",
    "acct.personalInfo.phone": "Phone Numbers",
    "acct.personalInfo.email": "Email",
    "acct.personalInfo.country": "Country or Region",
    "acct.personalInfo.birth": "Date of Birth",
    "acct.personalInfo.myInfo": "My Info",
    "acct.security.password": "Password",
    "acct.security.twoFactor": "Two-Factor Authentication",
    "acct.security.passkeys": "Passkeys",
    "acct.security.recovery": "Recovery Contacts",
    "acct.security.recoveryKey": "Recovery Key",
    "acct.payment.methods": "Payment Methods",
    "acct.payment.shipping": "Shipping Address",
    "acct.payment.subs": "Subscriptions",
    "acct.payment.orders": "Purchase History",
    "acct.family.members": "Family Members",
    "gen.about.name": "Computer Name",
    "gen.about.version": "macOS Version",
    "gen.softwareUpdate.auto": "Automatic Updates",
    "gen.storage.applications": "Applications",
    "gen.storage.documents": "Documents",
    "gen.storage.macos": "macOS",
    "gen.storage.systemData": "System Data",
    "gen.storage.bins": "Bins",
    "gen.appleCare.details": "AppleCare Coverage",
    "gen.language.list": "Languages",
    "gen.language.region": "Region",
    "gen.timeMachine.select": "Backup Disk",
    "spotlight.privacy": "Privacy",
    "desktopDock.displays": "Desktop & Stage Manager",
    "desktopDock.stageManager": "Stage Manager",
    "displays.nightShift": "Night Shift",
    "displays.trueTone": "True Tone",
    "wallpaper.dynamic": "Wallpaper Options",
    "notifications.appSettings": "Application Settings",
    "notifications.focus": "Focus",
    "notifications.summaries": "Notification Summaries",
    "focus.iCloud": "Focus & iCloud",
    "focus.schedules": "Schedules",
    "focus.filters": "Focus Filters",
    "screenTime.downtime": "Downtime",
    "screenTime.appLimits": "App Limits",
    "screenTime.alwaysAllowed": "Always Allowed",
    "screenTime.contentPrivacy": "Content & Privacy",
    "screenTime.viewReports": "View Reports",
    "lockScreen.requirePassword": "Require Password",
    "lockScreen.notifications": "Notifications & Password",
    "touchID.fingerprint": "Touch ID",
    "touchID.password": "Login Password",
    "users.guest": "Guest User",
    "users.autoLogin": "Automatic Login",
    "internetAccounts.add": "Add Account",
    "gameCenter.profile": "Profile",
    "gameCenter.friends": "Friends",
    "icloud.storage": "iCloud+ & Storage",
    "icloud.privateRelay": "Private Relay",
    "icloud.hideMyEmail": "Hide My Email",
    "icloud.family": "Family",
    "keyboard.input": "Keyboard Input",
    "keyboard.dictation": "Dictation",
    "keyboard.textReplacements": "Text Replacements",
    "keyboard.hardware": "Hardware",
    "trackpad.pointClick": "Point & Click",
    "trackpad.scrollZoom": "Scroll & Zoom",
    "trackpad.moreGestures": "More Gestures",
    "printers.add": "Add Printer",
    "printers.options": "Default Printer"
}

// ============ Root pages ============
content["wifi"] = [
    { header: "Known Network", rows: [
        { t: "Home_5G", s: "Connected", to: "wifi.details", v: "✓" },
        { t: "Home_2.4G", to: "wifi.details" },
        { t: "Neighbors_5G", to: "wifi.details" }
    ] },
    { header: "Other Networks", rows: [
        { t: "Cafe-Guest", to: "wifi.details" },
        { t: "TP-Link_A4F2", to: "wifi.details" }
    ] },
    { header: "Options", rows: [
        { t: "Wi-Fi", sw: true, on: true },
        { t: "Ask to join networks", v: "Notify" },
        { t: "Ask to join hotspots", v: "Ask to Join" },
        { t: "Advanced…", c: true }
    ] },
    { note: "Wi-Fi lets you connect to the internet and local network." }
]

content["bluetooth"] = [
    { rows: [
        { t: "Bluetooth", sw: true, on: true },
        { t: "Now discoverable as \"Mac Pro\"", dim: true }
    ] },
    { header: "My Devices", rows: [
        { t: "AirPods Pro", s: "Connected", v: "100%" },
        { t: "Magic Mouse", s: "Connected", v: "84%" },
        { t: "Keychron K3", s: "Not Connected" }
    ] },
    { header: "Nearby Devices", rows: [
        { t: "Searching…", dim: true }
    ] }
]

content["network"] = [
    { rows: [
        { t: "Wi-Fi", s: "Home_5G", to: "wifi.details", c: true },
        { t: "Ethernet", s: "Not Connected", c: true },
        { t: "VPN", s: "Off", to: "network.vpn", c: true }
    ] },
    { header: "Other Services", rows: [
        { t: "Bluetooth PAN", s: "Off", c: true },
        { t: "Thunderbolt Bridge", s: "Not Connected", c: true }
    ] },
    { header: "Options", rows: [
        { t: "Firewall", sw: false, on: false, to: "privacy.firewall" },
        { t: "Location Services", sw: true, on: true, to: "privacy.locationServices" }
    ] }
]
content["network.vpn"] = [
    { rows: [ { t: "Add VPN Configuration…", c: true } ] },
    { note: "VPN connections you add appear here." }
]
content["privacy.firewall"] = [
    { rows: [
        { t: "Firewall", sw: false, on: false },
        { t: "Block all incoming connections", sw: false, on: false },
        { t: "Automatically allow built-in software to receive incoming connections", sw: true, on: true },
        { t: "Automatically allow downloaded signed software to receive incoming connections", sw: true, on: true },
        { t: "Enable stealth mode", sw: false, on: false }
    ] },
    { note: "The firewall blocks unwanted network connections from other computers." }
]

content["battery"] = [
    { header: "Battery", rows: [
        { t: "Battery Level", v: "84%" },
        { t: "Time on Battery", v: "4:32 remaining" },
        { t: "Power Source", v: "Battery" }
    ] },
    { header: "Options", rows: [
        { t: "Low Power Mode", v: "Never" },
        { t: "Show battery percentage in menu bar", sw: true, on: true },
        { t: "Optimise video watching while on battery", sw: true, on: true }
    ] },
    { header: "Battery Health", rows: [
        { t: "Condition", v: "Normal", to: "battery.health" },
        { t: "Maximum Capacity", v: "96%" }
    ] }
]
content["battery.health"] = [
    { rows: [
        { t: "Normal", s: "Battery is functioning normally.", dim: true },
        { t: "Manage battery charging…", c: true }
    ] },
    { note: "Optimised Battery Charging reduces battery ageing by learning your daily charging routine." }
]

content["energy"] = [
    { header: "Energy Mode", rows: [
        { t: "Low Power", sw: false, on: false },
        { t: "Automatic", sw: true, on: true },
        { t: "High Power", sw: false, on: false }
    ] },
    { header: "Options", rows: [
        { t: "Prevent automatic sleeping on power adapter when the display is off", sw: false, on: false },
        { t: "Wake for network access", sw: true, on: true }
    ] }
]

content["appearance"] = [
    { header: "Appearance", rows: [
        { t: "Light", sw: false, on: false },
        { t: "Dark", sw: false, on: true },
        { t: "Auto", sw: false, on: false }
    ] },
    { header: "Accent Colour", rows: [
        { t: "Multicolour", sw: false, on: false },
        { t: "Blue", sw: true, on: false },
        { t: "Purple", sw: false, on: false }
    ] },
    { header: "Sidebar", rows: [
        { t: "Sidebar icon size", v: "Medium" },
        { t: "Allow wallpaper tinting in windows", sw: true, on: true }
    ] },
    { header: "Highlight Colour", rows: [
        { t: "Graphite", sw: false, on: true },
        { t: "Blue", sw: false, on: false }
    ] },
    { header: "Scroll Bars", rows: [
        { t: "Automatically based on mouse or trackpad", sw: true, on: true },
        { t: "When scrolling", sw: false, on: false },
        { t: "Always", sw: false, on: false }
    ] },
    { header: "Show scroll bars", rows: [
        { t: "Double-click a window's title bar to", v: "Zoom" }
    ] }
]

content["siri"] = [
    { rows: [
        { t: "Apple Intelligence", sw: true, on: true },
        { t: "Siri", sw: true, on: true },
        { t: "Listen for", v: "\"Siri\"" },
        { t: "Keyboard shortcut", v: "Hold ⌘ Space" },
        { t: "Language", v: "English (United States)" },
        { t: "Voice", v: "Voice 4" }
    ] },
    { header: "Siri & Dictation History", rows: [
        { t: "Delete Siri & Dictation History…", red: true, c: true }
    ] },
    { note: "Apple Intelligence is a personal intelligence system built into your Mac." }
]

content["desktopDock"] = [
    { header: "Desktop & Stage Manager", rows: [
        { t: "Show items on desktop", sw: true, on: true, to: "desktopDock.displays" },
        { t: "Click wallpaper to reveal desktop", v: "Only in Stage Manager" },
        { t: "Stage Manager", sw: false, on: false, to: "desktopDock.stageManager" }
    ] },
    { header: "Desktop & Dock", rows: [
        { t: "Automatically hide and show the Dock", sw: false, on: false },
        { t: "Animate opening applications", sw: true, on: true },
        { t: "Show indicators for open applications", sw: true, on: true },
        { t: "Group windows by application", sw: false, on: false },
        { t: "Delay before hiding", v: "0.5 seconds" },
        { t: "Size", v: "Medium" },
        { t: "Position on screen", v: "Bottom" },
        { t: "Minimise windows using", v: "Genie Effect" }
    ] },
    { header: "Widgets", rows: [
        { t: "Show widgets", sw: true, on: true },
        { t: "Desktop widgets", sw: true, on: true },
        { t: "Widget style", v: "Automatic" }
    ] },
    { header: "Windows", rows: [
        { t: "Tile by dragging windows to screen edges", sw: true, on: true },
        { t: "Hold ⌥ key while dragging windows to tile", sw: true, on: true },
        { t: "Drag windows to menu bar to fill screen", sw: true, on: true }
    ] },
    { header: "Mission Control", rows: [
        { t: "Automatically rearrange Spaces", sw: false, on: false },
        { t: "When switching to an application, switch to a Space with open windows", sw: true, on: true },
        { t: "Group windows by application", sw: false, on: false },
        { t: "Displays have separate Spaces", sw: true, on: true }
    ] }
]

content["displays"] = [
    { rows: [
        { t: "Brightness", v: "70%" },
        { t: "Automatically adjust brightness", sw: true, on: true },
        { t: "True Tone", sw: true, on: true, to: "displays.trueTone" }
    ] },
    { header: "Colour", rows: [
        { t: "Night Shift…", c: true, to: "displays.nightShift" },
        { t: "Profile", v: "Color LCD" }
    ] },
    { header: "Display", rows: [
        { t: "Resolution", v: "Default for display" },
        { t: "Refresh rate", v: "ProMotion" },
        { t: "Show all resolutions", sw: false, on: false }
    ] },
    { header: "Advanced", rows: [
        { t: "Show resolutions scaled", sw: false, on: false },
        { t: "Automatically adjust brightness", sw: true, on: true }
    ] }
]

content["spotlight"] = [
    { header: "Search Results", rows: [
        { t: "Applications", sw: true, on: true },
        { t: "Calculator", sw: true, on: true },
        { t: "Calendar Events", sw: true, on: true },
        { t: "Contacts", sw: true, on: true },
        { t: "Documents", sw: true, on: true },
        { t: "Folders", sw: true, on: true },
        { t: "Images", sw: true, on: true },
        { t: "Mail & Messages", sw: true, on: true },
        { t: "Maps", sw: true, on: true },
        { t: "Music & Podcasts", sw: true, on: true },
        { t: "Notes", sw: true, on: true },
        { t: "PDFs", sw: true, on: true },
        { t: "Presentations", sw: true, on: true },
        { t: "Spreadsheets", sw: true, on: true },
        { t: "System Preferences", sw: true, on: true },
        { t: "Tombstones", sw: false, on: false },
        { t: "Web video", sw: true, on: true }
    ] },
    { header: "Privacy", rows: [
        { t: "Search Results", c: true, to: "spotlight.privacy" }
    ] }
]

content["wallpaper"] = [
    { rows: [
        { t: "Wallpaper", v: "macOS Tahoe", to: "wallpaper.dynamic" },
        { t: "Show on all Spaces", sw: true, on: true },
        { t: "Show wallpaper picture in Stage Manager", sw: true, on: true }
    ] },
    { header: "Dynamic Desktop", rows: [
        { t: "Dynamic", sw: true, on: true },
        { t: "Light Still", sw: false, on: false },
        { t: "Dark Still", sw: false, on: false }
    ] },
    { header: "Collections", rows: [
        { t: "macOS", c: true },
        { t: "Dynamic Desktop", c: true },
        { t: "Aerials", c: true },
        { t: "Pictures…", c: true }
    ] }
]

content["notifications"] = [
    { header: "Application Notifications", rows: [
        { t: "Calendar", to: "notifications.appSettings" },
        { t: "Mail", to: "notifications.appSettings" },
        { t: "Messages", to: "notifications.appSettings" },
        { t: "Safari", to: "notifications.appSettings" },
        { t: "System Settings", to: "notifications.appSettings" }
    ] },
    { header: "Notification Centre", rows: [
        { t: "Show previews", v: "When Unlocked" },
        { t: "Allow notifications when the display is sleeping", sw: true, on: true },
        { t: "Allow notifications when the screen is locked", sw: true, on: true },
        { t: "Allow notifications when mirroring or sharing the display", sw: false, on: false }
    ] },
    { header: "Options", rows: [
        { t: "Focus", to: "notifications.focus" },
        { t: "Notification Summaries", to: "notifications.summaries" },
        { t: "Smart Summary", sw: true, on: true },
        { t: "Siri Suggestions", sw: true, on: true }
    ] }
]

content["sound"] = [
    { header: "Output", rows: [
        { t: "Mac Pro Speakers", s: "Built-in", c: true, to: "sound.output" },
        { t: "Volume", v: "50%" },
        { t: "Play sound on startup", sw: true, on: true }
    ] },
    { header: "Input", rows: [
        { t: "Mac Pro Microphone", s: "Built-in", c: true, to: "sound.input" },
        { t: "Input volume", v: "60%" },
        { t: "Alert volume", v: "50%" }
    ] },
    { header: "Sound Effects", rows: [
        { t: "Sound Effects", c: true, to: "sound.effects" },
        { t: "Play user interface sound effects", sw: true, on: true },
        { t: "Play feedback when volume is changed", sw: false, on: false }
    ] },
    { header: "Output Device", rows: [
        { t: "Show sound in menu bar", v: "Always" }
    ] }
]

content["focus"] = [
    { header: "Focus", rows: [
        { t: "Do Not Disturb", sw: false, on: false, to: "focus.schedules" },
        { t: "Work", sw: false, on: false, to: "focus.schedules" },
        { t: "Personal", sw: false, on: false, to: "focus.schedules" },
        { t: "Sleep", sw: false, on: false, to: "focus.schedules" }
    ] },
    { header: "Focus Status", rows: [
        { t: "Share Focus status", sw: true, on: true },
        { t: "Focus filters", c: true, to: "focus.filters" }
    ] },
    { header: "Options", rows: [
        { t: "Share across devices", sw: true, on: true, to: "focus.iCloud" },
        { t: "Smart Activation", sw: false, on: false },
        { t: "Add Schedule…", c: true, to: "focus.schedules" }
    ] },
    { note: "When a Focus is on, notifications from apps and people will be silenced." }
]

content["screenTime"] = [
    { rows: [
        { t: "App & Website Activity", sw: false, on: false, to: "screenTime.viewReports" },
        { t: "Communication Limits", sw: false, on: false },
        { t: "Downtime", sw: false, on: false, to: "screenTime.downtime" },
        { t: "Content & Privacy", sw: false, on: false, to: "screenTime.contentPrivacy" }
    ] },
    { header: "Limits", rows: [
        { t: "App Limits", sw: false, on: false, to: "screenTime.appLimits" },
        { t: "Always Allowed", c: true, to: "screenTime.alwaysAllowed" }
    ] },
    { header: "Options", rows: [
        { t: "Share across devices", sw: true, on: true },
        { t: "Lock Screen Time Settings", sw: false, on: false }
    ] },
    { header: "Reports", rows: [
        { t: "Week", c: true, to: "screenTime.viewReports" },
        { t: "Day", c: true, to: "screenTime.viewReports" }
    ] }
]

content["lockScreen"] = [
    { header: "Password", rows: [
        { t: "Require password after screen saver begins or display is turned off", v: "Immediately", to: "lockScreen.requirePassword" },
        { t: "Start Screen Saver when inactive", v: "20 minutes" }
    ] },
    { header: "Show large text", rows: [
        { t: "Show large text", sw: false, on: false }
    ] },
    { header: "Notifications", rows: [
        { t: "Show notifications when locked", sw: true, on: true, to: "lockScreen.notifications" },
        { t: "Show previews", v: "When Unlocked" },
        { t: "Show Quick Notes", sw: true, on: true },
        { t: "Show widgets", sw: true, on: true }
    ] },
    { header: "Locked Message", rows: [
        { t: "Show message when locked", sw: false, on: false },
        { t: "Set Lock Message…", c: true }
    ] },
    { header: "Accessories", rows: [
        { t: "Allow accessories when locked", v: "Ask for New Accessories" }
    ] }
]

content["privacySecurity"] = [
    { header: "Security", rows: [
        { t: "Firewall", sw: false, on: false, to: "privacy.firewall" },
        { t: "FileVault", sw: false, on: false, to: "privacy.filevault" },
        { t: "Allow applications from", v: "App Store & Known Developers" },
        { t: "Turn Off Automatic Login…", red: true, c: true }
    ] },
    { header: "Privacy", rows: [
        { t: "Location Services", to: "privacy.locationServices" },
        { t: "Contacts", to: "privacy.contacts" },
        { t: "Calendars", to: "privacy.calendars" },
        { t: "Reminders", to: "privacy.reminders" },
        { t: "Photos", to: "privacy.photos" },
        { t: "Bluetooth", to: "privacy.bluetooth" },
        { t: "Microphone", to: "privacy.microphone" },
        { t: "Camera", to: "privacy.camera" },
        { t: "Screen & System Audio Recording", to: "privacy.screenRecording" },
        { t: "Focus", to: "privacy.focus" },
        { t: "Audio Input", to: "privacy.audioInput" },
        { t: "Full Disk Access", to: "privacy.fullDiskAccess" },
        { t: "Files and Folders", to: "privacy.filesFolders" },
        { t: "Developer Tools", to: "privacy.devTools" },
        { t: "Analytics & Improvements", to: "privacy.analytics" },
        { t: "Apple Advertising", to: "privacy.advertising" }
    ] },
    { header: "Extensions", rows: [
        { t: "Added Extensions", c: true },
        { t: "Sharing", c: true },
        { t: "Profiles", c: true, to: "gen.deviceManagement" }
    ] },
    { note: "Some features require your permission the first time they are used." }
]
content["privacy.filevault"] = [
    { rows: [
        { t: "FileVault is off", s: "Turn on FileVault to encrypt your startup disk.", dim: true },
        { t: "Turn On FileVault…", c: true }
    ] },
    { note: "FileVault encrypts the contents of your startup disk so your data stays secure." }
]

content["touchIDPassword"] = [
    { rows: [
        { t: "Touch ID & Password", sw: true, on: true, to: "touchID.fingerprint" },
        { t: "Add Fingerprint…", c: true, to: "touchID.fingerprint" },
        { t: "iPhone & Apple Watch", v: "None", c: true }
    ] },
    { header: "Password", rows: [
        { t: "Change Password…", c: true, to: "touchID.password" },
        { t: "Use Touch ID to unlock", sw: true, on: true },
        { t: "Use Touch ID for Apple Pay", sw: true, on: true },
        { t: "Use Touch ID to unlock your Mac", sw: true, on: true }
    ] },
    { header: "Options", rows: [
        { t: "Automatically log out after inactivity", sw: false, on: false },
        { t: "Require password immediately", sw: true, on: true }
    ] }
]

content["usersGroups"] = [
    { header: "Users", rows: [
        { t: "{name}", s: "Admin, Me", to: "users.edit" },
        { t: "Guest User", s: "Off", to: "users.guest" }
    ] },
    { header: "Options", rows: [
        { t: "Automatically log in as", v: "Off", to: "users.autoLogin" },
        { t: "Guest user", sw: false, on: false, to: "users.guest" },
        { t: "Network account server", v: "None", c: true }
    ] },
    { header: "Add", rows: [
        { t: "Add User, Group or Shared Account…", c: true }
    ] }
]

content["internetAccounts"] = [
    { header: "Accounts", rows: [
        { t: "iCloud", s: "{email}", c: true },
        { t: "Add Account…", c: true, to: "internetAccounts.add" }
    ] },
    { header: "Calendars", rows: [
        { t: "iCloud", v: "On" }
    ] },
    { header: "Notes", rows: [
        { t: "iCloud", v: "On" }
    ] }
]

content["gameCenter"] = [
    { rows: [
        { t: "Game Center", sw: true, on: true },
        { t: "Profile", c: true, to: "gameCenter.profile" },
        { t: "Nickname", v: "{name}" },
        { t: "Friends", c: true, to: "gameCenter.friends" },
        { t: "Privacy", v: "Friends Only" }
    ] },
    { header: "Game Center", rows: [
        { t: "Allow friends to send invitations", sw: true, on: true },
        { t: "Allow invites from", v: "Friends of Friends" },
        { t: "Game invites", sw: true, on: true },
        { t: "Multiplayer", sw: true, on: true },
        { t: "Nearby players", sw: true, on: true }
    ] }
]

content["icloud"] = [
    { rows: [
        { t: "Account", s: "{email}", c: true, to: "acct.personalInfo" },
        { t: "Storage", v: "5 GB of 5 GB used", c: true, to: "icloud.storage" }
    ] },
    { header: "Saved to iCloud", rows: [
        { t: "iCloud Drive", sw: true, on: true, to: "icloud.storage" },
        { t: "Photos", sw: true, on: true },
        { t: "Mail", sw: false, on: false },
        { t: "Contacts", sw: true, on: true },
        { t: "Calendars", sw: true, on: true },
        { t: "Reminders", sw: true, on: true },
        { t: "Notes", sw: true, on: true },
        { t: "Safari", sw: true, on: true },
        { t: "Passwords", sw: true, on: true },
        { t: "Voice Memos", sw: true, on: true },
        { t: "Find My Mac", sw: true, on: true, to: "acct.findMy" }
    ] },
    { header: "iCloud+", rows: [
        { t: "iCloud Private Relay", sw: true, on: true, to: "icloud.privateRelay" },
        { t: "Hide My Email", c: true, to: "icloud.hideMyEmail" },
        { t: "Custom Email Domain", c: true },
        { t: "HomeKit Secure Video", sw: false, on: false },
        { t: "Family", c: true, to: "icloud.family" }
    ] },
    { header: "Advanced", rows: [
        { t: "Keychain", sw: true, on: true },
        { t: "Use iCloud Drive for Desktop & Documents Folders", sw: false, on: false },
        { t: "Optimise Mac Storage", sw: true, on: true }
    ] }
]

content["walletApplePay"] = [
    { rows: [
        { t: "Apple Cash", s: "Set up", c: true },
        { t: "Apple Card", s: "Set up", c: true },
        { t: "Add Card…", c: true }
    ] },
    { header: "Options", rows: [
        { t: "Apple Pay", sw: true, on: true },
        { t: "Confirm with Touch ID", sw: true, on: true },
        { t: "Allow payments on the web", sw: true, on: true }
    ] },
    { header: "Shipping & Billing", rows: [
        { t: "Shipping Addresses", c: true, to: "acct.payment.shipping" },
        { t: "Payment Cards", c: true, to: "acct.payment.methods" }
    ] },
    { note: "Wallet lets you keep cards, tickets, and keys in one place." }
]

content["keyboard"] = [
    { rows: [
        { t: "Key Repeat Rate", v: "Fast" },
        { t: "Delay Until Repeat", v: "Short" },
        { t: "Adjust keyboard brightness in low light", sw: true, on: true }
    ] },
    { header: "Text Input", rows: [
        { t: "Input Sources", c: true, to: "keyboard.input" },
        { t: "Dictation", sw: false, on: false, to: "keyboard.dictation" },
        { t: "Text Replacements…", c: true, to: "keyboard.textReplacements" }
    ] },
    { header: "Shortcuts", rows: [
        { t: "Keyboard Shortcuts…", c: true, to: "keyboard.input" },
        { t: "Modifier keys…", c: true, to: "keyboard.hardware" },
        { t: "Turn keyboard backlight off after inactivity", v: "5 seconds" }
    ] }
]

content["trackpad"] = [
    { rows: [
        { t: "Point & Click", c: true, to: "trackpad.pointClick" },
        { t: "Scroll & Zoom", c: true, to: "trackpad.scrollZoom" },
        { t: "More Gestures", c: true, to: "trackpad.moreGestures" }
    ] },
    { header: "Accessibility", rows: [
        { t: "Silent clicking", sw: false, on: false },
        { t: "Force Click and haptic feedback", sw: true, on: true },
        { t: "Tracking speed", v: "Normal" }
    ] }
]

content["printersScanners"] = [
    { rows: [
        { t: "No printers", dim: true },
        { t: "Add Printer, Scanner or Fax…", c: true, to: "printers.add" }
    ] },
    { header: "Options", rows: [
        { t: "Default printer", v: "Last Printer Used", to: "printers.options" },
        { t: "Default paper size", v: "A4", to: "printers.options" }
    ] },
    { note: "Printers on your network are added automatically." }
]

content["accessibility"] = [
    { header: "Vision", rows: [
        { t: "VoiceOver", c: true, to: "acc.voiceOver" },
        { t: "Zoom", c: true, to: "acc.zoom" },
        { t: "Display", c: true, to: "acc.display" },
        { t: "Motion", c: true, to: "acc.motion" },
        { t: "VoiceOver", s: "Off", c: true, to: "acc.voiceOver" }
    ] },
    { header: "Hearing", rows: [
        { t: "Hearing Devices", c: true, to: "acc.hearingDevices" },
        { t: "Audio", c: true, to: "acc.hearingAudio" },
        { t: "RTT", c: true, to: "acc.rtt" },
        { t: "Audio Descriptions", c: true, to: "acc.audioDescriptions" }
    ] },
    { header: "Motor", rows: [
        { t: "Voice Control", c: true, to: "acc.voiceControl" },
        { t: "Keyboard", c: true, to: "keyboard" },
        { t: "Pointer Control", c: true, to: "acc.pointerControl" },
        { t: "Switch Control", c: true, to: "acc.switchControl" }
    ] },
    { header: "General", rows: [
        { t: "Read & Speak", c: true, to: "acc.readSpeak" },
        { t: "Hover Text", c: true, to: "acc.hoverText" },
        { t: "Siri", c: true, to: "siri" },
        { t: "Shortcut", v: "Triple-press Touch ID" }
    ] },
    { note: "Accessibility features make it easier to see, hear, and interact with your Mac." }
]
