// Keep future/optional native actions reachable without duplicating primary controls.
function extraActions(entries, labels) {
    var result=[]
    for(var i=0; entries && i<entries.length; i++) {
        var e=entries[i]
        if (!e.isSeparator && !e.hasChildren && e.enabled && !roleFor(e.text, labels)) result.push(e)
    }
    return result
}
// Extra native actions can contain calendar titles. Mask every presentation
// surface together; keep the original entry only for invoking its native action.
function extraActionText(text, hideTitles, hiddenLabel, hiddenDescription) {
    return hideTitles ? {label:hiddenLabel, description:hiddenDescription}
                      : {label:literal(text,24), description:literal(text)}
}
function modeFor(connected, recording, paused) { return !connected ? "offline" : recording ? (paused ? "paused" : "recording") : "ready" }
function isYogurt(item) {
    var identity = String(item.id || "") + " " + String(item.title || "") + " " + String(item.tooltipTitle || "")
    return /(^|[^a-z])yogurt([^a-z]|$)/i.test(identity)
}
function literal(value, limit) { return String(value === undefined || value === null ? "" : value).slice(0, limit || 160) }
// WidgetButton's shared tooltip accepts rich text: remove markup-significant characters.
function tooltipText(value) { return literal(value, 240).replace(/[<>&]/g, "") }
function cleanLabel(value) { return literal(value).replace(/&/g, "").replace(/…/g, "").trim().toLocaleLowerCase() }
function roleFor(text, labels) {
    var value = cleanLabel(text)
    for (var role in labels) for (var i = 0; i < labels[role].length; i++)
        if (cleanLabel(labels[role][i]) === value) return role
    return ""
}
function pick(entries, role, labels) {
    for (var i = 0; entries && i < entries.length; i++)
        if (!entries[i].isSeparator && roleFor(entries[i].text, labels) === role) return entries[i]
    return null
}
function elapsed(start, now) {
    var seconds = Math.max(0, Math.floor((now - Number(start || now)) / 1000))
    var minutes = Math.floor(seconds / 60)
    return minutes >= 60 ? Math.floor(minutes / 60) + ":" + String(minutes % 60).padStart(2, "0") + ":" + String(seconds % 60).padStart(2, "0")
                         : String(minutes).padStart(2, "0") + ":" + String(seconds % 60).padStart(2, "0")
}
function duration(ms) { return elapsed(1, Math.max(0, Number(ms || 0)) + 1) }
function safeCommand(value) {
    if (!Array.isArray(value) || !value.length || value.length > 16) return []
    for (var i = 0; i < value.length; i++) if (typeof value[i] !== "string" || value[i].length > 2048 || value[i].indexOf("\u0000") >= 0) return []
    return value
}
if (typeof module !== "undefined") module.exports = {extraActionText:extraActionText,extraActions:extraActions,modeFor:modeFor,isYogurt:isYogurt,literal:literal,tooltipText:tooltipText,roleFor:roleFor,pick:pick,elapsed:elapsed,duration:duration,safeCommand:safeCommand}
