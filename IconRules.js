.pragma library

var DEFAULT_ICON = "󰀻"

// Title rules only apply to browsers, so a terminal titled "github" keeps its terminal icon.
var titleRuleClasses = /firefox|librewolf|floorp|waterfox|zen|chrom|brave|edge|vivaldi|opera|helium|thorium/

var titleRules = [
  { match: /youtube/, icon: "󰗃" },
  { match: /chatgpt/, icon: "󰭹" },
  { match: /claude/, icon: "󰭹" },
  { match: /gemini/, icon: "󰭹" },
  { match: /github/, icon: "󰊤" }
]

// Class rules are cached per class by the caller, so they must never depend on the title.
var classRules = [
  { match: /ghostty|alacritty|kitty|wezterm|^foot$|foot-?client|konsole|gnome-terminal|ptyxis/, icon: "\ue795" },

  { match: /firefox|librewolf|floorp|waterfox|zen-browser|^zen$/, icon: "󰈹" },
  { match: /microsoft-edge/, icon: "󰇩" },
  { match: /brave/, icon: "" },
  { match: /tor browser/, icon: "󰖂" },
  { match: /chromium|thorium|google-chrome/, icon: "󰊯" },

  { match: /code-url-handler|code-oss|codium|^code$|visual-studio-code/, icon: "󰨞" },
  { match: /dev\.zed\.zed/, icon: "󱓞" },
  { match: /^n?vim$|neovim/, icon: "" },

  { match: /discord|webcord|vesktop/, icon: "󰙯" },
  { match: /^slack$/, icon: "󰒱" },
  { match: /signal/, icon: "󰍡" },
  { match: /telegram/, icon: "󰘦" },
  { match: /whatsapp|zapzap/, icon: "󰖣" },

  { match: /rhythmbox/, icon: "󰝚" },
  { match: /^obs$|com\.obsproject\.studio/, icon: "󰐍" },

  { match: /virt-manager|virtualbox/, icon: "󰍺" },
  { match: /remmina/, icon: "󰢹" },
  { match: /pavucontrol/, icon: "󰓃" },
  { match: /gparted/, icon: "󰋊" },

  { match: /libreoffice-writer/, icon: "󰈙" },
  { match: /libreoffice-calc/, icon: "󰧷" },
  { match: /libreoffice/, icon: "󰈙" },

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
