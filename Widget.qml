// SPDX-License-Identifier: MIT
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "NativeLabels.js" as NativeLabels

BarWidget {
    id: root
    moduleName: "bjl.yogurt"
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    property bool menuOpen: false
    readonly property bool opened: menuOpen
    readonly property var hostWindow: root.QsWindow.window
    property var library: ({available:false, recent:[], recording:null})
    property double now: Date.now()
    property string errorText: ""
    readonly property bool hideTitles: setting("hideTitles", false) === true
    readonly property string profileDirectory: String(setting("profileDirectory", ""))
    readonly property var trayItem: {
        var items = SystemTray.items.values
        for (var i = 0; i < items.length; i++) {
            if (Model.isYogurt(items[i])) return items[i]
        }
        return null
    }
    readonly property var nativeEntries: nativeMenu.children.values
    readonly property bool paused: !!Model.pick(nativeEntries, "resume", NativeLabels.labels)
    readonly property bool recording: !!trayItem && (!!Model.pick(nativeEntries, "stop", NativeLabels.labels) || !!library.recording)
    readonly property string elapsed: {
        if (library.recording) return Model.elapsed(library.recording.startedAt, now)
        var tooltip = trayItem ? String(trayItem.tooltipTitle || "") + " " + String(trayItem.tooltipDescription || "") : ""
        var timer = tooltip.match(/\b\d{1,2}:\d{2}(?::\d{2})?\b/)
        return timer ? timer[0] : "—"
    }
    readonly property string mode: Model.modeFor(!!trayItem, recording, paused)
    readonly property color accent: mode === "recording" ? "#fb7185" : mode === "paused" ? "#fbbf24" : "#a78bfa"
    readonly property var roleEntries: ({
        start: Model.pick(nativeEntries, "start", NativeLabels.labels),
        pause: Model.pick(nativeEntries, "pause", NativeLabels.labels),
        resume: Model.pick(nativeEntries, "resume", NativeLabels.labels),
        stop: Model.pick(nativeEntries, "stop", NativeLabels.labels),
        open: Model.pick(nativeEntries, "open", NativeLabels.labels),
        ask: Model.pick(nativeEntries, "ask", NativeLabels.labels),
        settings: Model.pick(nativeEntries, "settings", NativeLabels.labels),
        quit: Model.pick(nativeEntries, "quit", NativeLabels.labels)
    })
    function focusedWidget() {
        var peers = root.bar && root.bar.moduleWidgets ? root.bar.moduleWidgets(root.moduleName) : [root]
        var monitor = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        for (var i=0;i<peers.length;i++) if (peers[i].hostWindow && peers[i].hostWindow.screen && peers[i].hostWindow.screen.name === monitor) return peers[i]
        return root
    }
    function open() { menuOpen=true; refresh(); Qt.callLater(function(){view.forceActiveFocus()}) }
    function close() { menuOpen=false }
    function toggle() { if(menuOpen)close();else open() }
    function refresh() { if (!poll.running) poll.running=true }
    function invokeRole(role) {
        var entry = Model.pick(nativeMenu.children.values, role, NativeLabels.labels)
        if (!entry || !entry.enabled) return
        entry.triggered()
        refreshSoon.restart()
    }
    function openYogurt() {
        var entry = Model.pick(nativeEntries, "open", NativeLabels.labels)
        if (entry && entry.enabled) { entry.triggered(); return }
        var command = Model.safeCommand(setting("launchCommand", ["gtk-launch", "yogurt"]))
        if (command.length) { launch.command=command; if(!launch.running)launch.running=true }
        else errorText=strings.t("launch.error")
    }
    QsMenuOpener { id:nativeMenu; menu:root.trayItem ? root.trayItem.menu : null }
    Translations { id:strings; directory:Qt.resolvedUrl("i18n") }
    IpcHandler {
        target:"bjl.yogurt"
        enabled:!!root.hostWindow && !!root.hostWindow.screen && Quickshell.screens.length>0 && root.hostWindow.screen.name === Quickshell.screens[0].name
        function toggleMenu(): void { root.focusedWidget().toggle() }
        function statusText(): string { return JSON.stringify({mode:root.mode,elapsed:root.elapsed,connected:!!root.trayItem,libraryAvailable:!!root.library.available,lastPollAt:root.library.updatedAt||0,controls:Object.keys(root.roleEntries).filter(k=>!!root.roleEntries[k])}) }
        function panelGeometry(): string { return JSON.stringify({open:menu.open,x:menu.cardOrigin.x,y:menu.cardOrigin.y,width:menu.contentWidth,height:menu.drawnHeight,screen:root.hostWindow&&root.hostWindow.screen?root.hostWindow.screen.name:""}) }
    }
    Process {
        id:poll
        command:["python3","-B",Qt.resolvedUrl("status.py").toString().replace("file://", "")].concat(root.profileDirectory ? ["--profile",root.profileDirectory] : [])
        stdout:StdioCollector {
            onStreamFinished: {
                try { root.library=JSON.parse(text) }
                catch(e) { root.library={available:false,recent:[],recording:null,message:"library-unavailable"} }
            }
        }
    }
    Process { id:launch; onExited:exitCode=>{ if(exitCode!==0)root.errorText=strings.t("launch.error");refreshSoon.restart() } }
    Timer { id:refreshSoon;interval:750;onTriggered:root.refresh() }
    Timer { interval:2000;running:true;repeat:true;triggeredOnStart:true;onTriggered:root.refresh() }
    Timer { interval:1000;running:root.recording||root.menuOpen;repeat:true;onTriggered:root.now=Date.now() }
    WidgetButton {
        id:button
        bar:root.bar;text:"";labelVisible:false;hasVisualContent:true
        fixedWidth:vertical?barSize:markRow.implicitWidth+Style.space(18)
        fixedHeight:vertical?barSize:-1
        tooltipText:Model.tooltipText("Yogurt Bar · "+strings.t(root.mode)+(root.recording?" · "+root.elapsed:""))
        Row {
            id:markRow;anchors.centerIn:parent;spacing:Style.space(7)
            Item {
                width:Style.space(20);height:width
                Image {anchors.fill:parent;source:Qt.resolvedUrl("assets/yogurt.png");sourceSize:Qt.size(64,64);smooth:true;opacity:root.mode==="offline"?.45:1}
                Rectangle {visible:root.recording;anchors.right:parent.right;anchors.bottom:parent.bottom;width:Style.space(7);height:width;radius:width/2;color:root.accent;border.width:1;border.color:Color.background}
            }
            Text {visible:root.recording&&!root.vertical;text:root.elapsed;textFormat:Text.PlainText;color:root.accent;font.family:"monospace";font.pixelSize:Style.font.bodySmall;font.bold:true;anchors.verticalCenter:parent.verticalCenter}
        }
        onPressed:mouseButton=>{if(mouseButton===Qt.RightButton)root.openYogurt();else root.toggle()}
    }
    KeyboardPanel {
        id:menu;anchorItem:button;bar:root.bar;owner:root;open:root.menuOpen
        WlrLayershell.namespace:"yogurt-bar"
        padding:0
        contentWidth:menu.fittedContentWidth(Style.space(390))
        contentHeight:menu.fittedContentHeight(view.implicitHeight)
        focusTarget:view
        YogurtPanel {
            id:view;width:parent.width
            mode:root.mode;accent:root.accent;elapsed:root.elapsed;library:root.library
            hideTitles:root.hideTitles;now:root.now;roleEntries:root.roleEntries
            nativeEntries:root.nativeEntries;extraActions:Model.extraActions(root.nativeEntries, NativeLabels.labels);errorText:root.errorText
            onRequest:role=>root.invokeRole(role)
            onOpenApp:root.openYogurt()
            onDismiss:root.close()
            onRefresh:root.refresh()
            onNativeAction:entry=>{ if(entry && entry.enabled && !entry.hasChildren){entry.triggered();refreshSoon.restart()} }
        }
    }
}
