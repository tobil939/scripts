# Grundlegende Konfiguration für qutebrowser
config.load_autoconfig()

# :tabnew für einen neuen Tab (mit oder ohne URL)
# config.bind(':tabnew', 'open -t')
c.aliases["tabnew"] = "open -t"

# :tabs zeigt die Liste der offenen Tabs an
# config.bind(':tabs', 'tab-list')
c.aliases["tabs"] = "tab-select"

# :tabclose schließt den aktuellen Tab
# config.bind(':tabclose', 'tab-close')
c.aliases["tabclose"] = "tab-close"

# :tabonly schließt alle Tabs außer dem aktuellen
# config.bind(':tabonly', 'tab-only')
c.aliases["tabonly"] = "tab-only"

# :vs für vertikalen Split (zwei Tabs nebeneinander)
# config.bind(':vs', 'window-only ;; spawn --userscript qutebrowser_split')
c.aliases["vs"] = "open -w"

# Normal-Modus: gt für nächsten Tab
config.bind("gt", "tab-next")

# Normal-Modus: gT für vorherigen Tab
config.bind("gT", "tab-prev")

# Normal-Modus: 2gt für zweiten Tab (numerische Auswahl)
config.bind("2gt", "tab-select 2")
config.bind("3gt", "tab-select 3")
config.bind("4gt", "tab-select 4")
config.bind("5gt", "tab-select 5")
config.bind("6gt", "tab-select 6")
config.bind("7gt", "tab-select 7")
config.bind("8gt", "tab-select 8")
config.bind("9gt", "tab-select 9")

# Zurueck in History
config.bind("u", "back")

# ZurueckZuruek in History (forward)
config.bind("U", "forward")

# Dark Mode aktivieren
c.colors.webpage.darkmode.enabled = True

# Shortcut zum Umschalten des Dark Mode (z. B. F12)
config.bind("<F12>", "config-cycle colors.webpage.darkmode.enabled")

# Optional: Startseite setzen
c.url.start_pages = ["https://www.google.com"]

# Optional: Feintuning des Dark Mode (Beispiel)
c.colors.webpage.darkmode.policy.images = "never"  # Keine invertierten Bilder

c.fonts.hints = "normal 20pt DejaVu Sans"
