import QtQuick
import Quickshell
import Quickshell.Io
import ".."

QtObject {
    id: quoteService

    property var configRef: null
    property var quoteFetchQueue: []

    property Process quoteFetcher: Process {
        id: qFetcher
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let text = this.text ? this.text.trim() : ""
                    if (text.length > 0) {
                        let fetchedQuote = ""

                        if (text.startsWith("{") || text.startsWith("[")) {
                            let json = JSON.parse(text)
                            if (Array.isArray(json) && json.length > 0 && json[0].q) {
                                fetchedQuote = json[0].q + " — " + json[0].a
                            } else if (json.setup && json.punchline) {
                                fetchedQuote = json.setup + " " + json.punchline
                            } else if (json.quote) {
                                fetchedQuote = json.quote + " — " + json.author
                            }
                        } else {
                            fetchedQuote = text
                        }

                        if (fetchedQuote.length > 0 && configRef) {
                            configRef.addMascotPhrase(fetchedQuote)
                        }
                    }
                } catch (e) {
                    console.error("Failed to parse quote feed output:", e)
                }

                quoteService.processQuoteQueue()
            }
        }
    }

    function processQuoteQueue() {
        if (!configRef) return;
        let queue = quoteFetchQueue ? quoteFetchQueue.slice() : []
        if (queue.length === 0 || qFetcher.running || (configRef.mascotPhrases && configRef.mascotPhrases.length >= 20)) {
            quoteFetchQueue = []
            return
        }

        let nextSource = queue.shift()
        quoteFetchQueue = queue
        let cmd = ""

        if (nextSource === "zenquotes") {
            cmd = "curl -sS --max-time 5 'https://zenquotes.io/api/random'"
        } else if (nextSource === "jokeapi") {
            cmd = "curl -sS --max-time 5 'https://official-joke-api.appspot.com/random_joke'"
        } else if (nextSource === "rss" && configRef.rssFeedUrl !== "") {
            let pyParse = "import sys, xml.etree.ElementTree as ET, random; " +
                          "root = ET.fromstring(sys.stdin.read()); " +
                          "items = root.findall('.//item'); " +
                          "item = random.choice(items) if items else None; " +
                          "desc = item.find('description').text if item is not None and item.find('description') is not None else ''; " +
                          "title = item.find('title').text if item is not None and item.find('title') is not None else ''; " +
                          "print(f'{desc} — {title}' if desc and title else (desc or title))"
            
            cmd = "curl -sS -L --max-time 5 '" + configRef.rssFeedUrl + "' | python3 -c \"" + pyParse + "\""
        }

        if (cmd !== "") {
            qFetcher.command = ["fish", "-c", cmd]
            qFetcher.running = true
        } else {
            processQuoteQueue()
        }
    }

    function triggerQuoteFetch() {
        if (!configRef || !configRef.fetchOnlineQuotes) return

        let currentCount = configRef.mascotPhrases ? configRef.mascotPhrases.length : 0
        let needed = 20 - currentCount
        if (needed <= 0) return

        let activeSources = []
        if (configRef.quoteSource === "both" || configRef.quoteSource === "zenquotes") activeSources.push("zenquotes")
        if (configRef.quoteSource === "both" || configRef.quoteSource === "jokeapi") activeSources.push("jokeapi")
        if (configRef.quoteSource === "rss" && configRef.rssFeedUrl !== "") activeSources.push("rss")

        if (activeSources.length === 0) return

        let newQueue = []
        if (activeSources.length > 1) {
            let share = Math.floor(needed / activeSources.length)
            let remainder = needed % activeSources.length

            for (let s = 0; s < activeSources.length; s++) {
                let count = share + (s < remainder ? 1 : 0)
                for (let c = 0; c < count; c++) {
                    newQueue.push(activeSources[s])
                }
            }
        } else {
            let src = activeSources[0]
            for (let k = 0; k < needed; k++) newQueue.push(src)
        }

        quoteFetchQueue = newQueue
        processQuoteQueue()
    }

    property Timer quoteFetchTimer: Timer {
        interval: 900000
        running: (configRef ? (configRef.fetchOnlineQuotes && (!configRef.mascotPhrases || configRef.mascotPhrases.length < 20)) : false)
        repeat: true
        onTriggered: quoteService.triggerQuoteFetch()
    }
}
