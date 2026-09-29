.pragma library

// Class/title -> glyph resolution for open windows, split into two tiers:
//
//   titleRules  Small and checked on every lookup. These exist only for
//               apps that share one window class across many different
//               sites/services (mainly browser tabs), so the class alone
//               can't tell them apart.
//   classRules  Everything else, matched by window class. The caller is
//               expected to cache these by class, since a class is stable
//               for the lifetime of a window while its title is not.
//
// Keeping title-matching to a short, separate list (instead of interleaving
// title checks into one long ordered rule set) is what makes class-level
// caching safe: a cached class lookup never needs to be invalidated by a
// title change, because nothing later in the class list depends on title.

var DEFAULT_ICON = "󰀻"

// Title rules only disambiguate browser windows (tabs and web apps); a
// terminal whose title mentions "github" should still look like a terminal.
var titleRuleClasses = /firefox|librewolf|floorp|waterfox|zen|chrom|brave|edge|vivaldi|opera|helium|thorium/

var titleRules = [
  { match: /youtube/, icon: "󰗃" },
  { match: /chatgpt/, icon: "󰭹" },
  { match: /claude/, icon: "󰭹" },
  { match: /gemini/, icon: "󰭹" },
  { match: /github/, icon: "󰊤" }
]

var classRules = [
  // Terminals
  { match: /ghostty|alacritty|kitty|wezterm|^foot$|foot-?client|konsole|gnome-terminal|ptyxis/, icon: "\ue795" },

  // Browsers
  { match: /firefox|librewolf|floorp|waterfox|zen-browser|^zen$/, icon: "󰈹" },
  { match: /microsoft-edge/, icon: "󰇩" },
  { match: /brave/, icon: "" },
  { match: /tor browser/, icon: "󰖂" },
  { match: /chromium|thorium|google-chrome/, icon: "󰊯" },

  // Editors / IDEs
  { match: /code-url-handler|code-oss|codium|^code$|visual-studio-code/, icon: "󰨞" },
  { match: /dev\.zed\.zed/, icon: "󱓞" },
  { match: /^n?vim$|neovim/, icon: "" },

  // Chat / comms
  { match: /discord|webcord|vesktop/, icon: "󰙯" },
  { match: /^slack$/, icon: "󰒱" },
  { match: /signal/, icon: "󰍡" },
  { match: /telegram/, icon: "󰘦" },
  { match: /whatsapp|zapzap/, icon: "󰖣" },

  // Media
  { match: /rhythmbox/, icon: "󰝚" },
  { match: /^obs$|com\.obsproject\.studio/, icon: "󰐍" },

  // Dev / ops tooling
  { match: /virt-manager|virtualbox/, icon: "󰍺" },
  { match: /remmina/, icon: "󰢹" },
  { match: /pavucontrol/, icon: "󰓃" },
  { match: /gparted/, icon: "󰋊" },

  // Office / docs
  { match: /libreoffice-writer/, icon: "󰈙" },
  { match: /libreoffice-calc/, icon: "󰧷" },
  { match: /libreoffice/, icon: "󰈙" },

  // Games
  { match: /^steam$/, icon: "󰓓" }
]

function iconForTitle(title, cls) {
  if (!title || !titleRuleClasses.test(cls || "")) return ""
  for (var i = 0; i < titleRules.length; i++) {
    if (titleRules[i].match.test(title)) return titleRules[i].icon
  }
  return ""
}

function iconForClass(cls) {
  if (!cls) return ""
  for (var i = 0; i < classRules.length; i++) {
    if (classRules[i].match.test(cls)) return classRules[i].icon
  }
  return ""
}
