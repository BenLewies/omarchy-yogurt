// SPDX-License-Identifier: MIT
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

FocusScope {
    id:root
    property string mode:"offline"
    property color accent:"#a78bfa"
    property string elapsed:"00:00"
    property var library:({recent:[]})
    property var roleEntries:({})
    property var nativeEntries:[]
    property bool hideTitles:false
    property double now:Date.now()
    property string errorText:""
    property var extraActions:[]
    signal request(string role)
    signal openApp()
    signal dismiss()
    signal refresh()
    signal nativeAction(var entry)
    readonly property bool recording:mode==="recording"||mode==="paused"
    readonly property color ink:Color.foreground
    readonly property color muted:Qt.rgba(ink.r,ink.g,ink.b,.58)
    implicitHeight:content.implicitHeight
    Keys.onEscapePressed:root.dismiss()
    Translations {id:strings;directory:Qt.resolvedUrl("i18n")}
    ColumnLayout {
        id:content;width:parent.width;spacing:0
        Rectangle {
            Layout.fillWidth:true;implicitHeight:Style.space(100)
            gradient:Gradient {orientation:Gradient.Horizontal;GradientStop{position:0;color:"#302047"}GradientStop{position:1;color:"#181822"}}
            RowLayout {
                anchors.fill:parent;anchors.margins:Style.space(22);spacing:Style.space(13)
                Image {source:Qt.resolvedUrl("assets/yogurt.png");sourceSize:Qt.size(128,128);Layout.preferredWidth:Style.space(44);Layout.preferredHeight:Style.space(44);smooth:true}
                ColumnLayout {
                    Layout.fillWidth:true;spacing:Style.space(4)
                    Text{text:strings.t("name");textFormat:Text.PlainText;color:"#faf5ff";font.pixelSize:Style.space(23);font.bold:true}
                    Text{text:strings.t("tagline");textFormat:Text.PlainText;color:"#c4b5d7";font.pixelSize:Style.font.body}
                }
                Button {text:"×";foreground:"#e9d5ff";fontSize:Style.space(20);onClicked:root.dismiss();tooltipText:strings.t("close")}
            }
        }
        ColumnLayout {
            Layout.fillWidth:true;Layout.margins:Style.space(22);spacing:Style.space(18)
            RowLayout {
                Layout.fillWidth:true;spacing:Style.space(8)
                Rectangle{width:Style.space(7);height:width;radius:width/2;color:root.mode==="offline"?root.muted:root.accent}
                Text{Layout.fillWidth:true;text:strings.t(root.mode);textFormat:Text.PlainText;color:root.ink;font.pixelSize:Style.font.body;font.bold:true}
                Text{visible:root.recording;text:"LIVE";textFormat:Text.PlainText;color:root.accent;font.pixelSize:Style.space(10);font.letterSpacing:1.8;font.bold:true}
            }
            Text {
                visible:root.recording;Layout.fillWidth:true
                text:root.elapsed;textFormat:Text.PlainText;color:root.accent;font.family:"monospace";font.pixelSize:Style.space(43);font.weight:Font.Medium
            }
            Text {
                Layout.fillWidth:true
                text:strings.t(root.mode+".detail");textFormat:Text.PlainText;color:root.muted;font.pixelSize:Style.font.body;wrapMode:Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth:true;spacing:Style.space(8)
                Button {
                    Layout.fillWidth:true;verticalPadding:Style.space(11);bordered:true;focusable:true
                    id:primaryAction
                    text:"";implicitHeight:Style.space(44)
                    readonly property string actionLabel:root.mode==="offline"?strings.t("open"):root.recording?strings.t("stop"):strings.t("start")
                    Accessible.name:actionLabel
                    Row {
                        anchors.centerIn:parent;spacing:Style.space(9)
                        ToolIcon{anchors.verticalCenter:parent.verticalCenter;kind:root.mode==="offline"?"library":root.recording?"stop":"record";color:primaryAction.foreground;width:Style.space(19);height:width}
                        Text{anchors.verticalCenter:parent.verticalCenter;text:primaryAction.actionLabel;textFormat:Text.PlainText;color:primaryAction.foreground;font.pixelSize:Style.font.body}
                    }
                    foreground:root.mode==="recording"?"#fb7185":"#c4b5fd"
                    enabled:root.mode==="offline"||!!(root.recording?root.roleEntries.stop:root.roleEntries.start)
                    onClicked:{if(root.mode==="offline")root.openApp();else root.request(root.recording?"stop":"start")}
                }
                Button {
                    visible:root.recording;verticalPadding:Style.space(11);bordered:true;focusable:true
                    id:pauseAction
                    text:"";implicitHeight:Style.space(44);implicitWidth:Style.space(104)
                    Accessible.name:strings.t(root.mode==="paused"?"resume":"pause")
                    Row {
                        anchors.centerIn:parent;spacing:Style.space(7)
                        ToolIcon{anchors.verticalCenter:parent.verticalCenter;kind:root.mode==="paused"?"play":"pause";color:pauseAction.foreground;width:Style.space(18);height:width}
                        Text{anchors.verticalCenter:parent.verticalCenter;text:strings.t(root.mode==="paused"?"resume":"pause");textFormat:Text.PlainText;color:pauseAction.foreground;font.pixelSize:Style.font.body}
                    }
                    enabled:!!(root.mode==="paused"?root.roleEntries.resume:root.roleEntries.pause)
                    onClicked:root.request(root.mode==="paused"?"resume":"pause")
                }
            }
            Text {
                visible:root.mode!=="offline"&&!root.recording&&!root.roleEntries.start
                Layout.fillWidth:true;text:strings.t("controls.loading");textFormat:Text.PlainText;color:root.muted;font.pixelSize:Style.font.bodySmall;wrapMode:Text.WordWrap
            }
            Text {visible:root.errorText.length>0;Layout.fillWidth:true;text:root.errorText;textFormat:Text.PlainText;color:"#fb7185";font.pixelSize:Style.font.bodySmall;wrapMode:Text.WordWrap}
            Rectangle {Layout.fillWidth:true;height:1;color:root.ink;opacity:.10}
            RowLayout {
                Layout.fillWidth:true
                Text{Layout.fillWidth:true;text:strings.t("recent");textFormat:Text.PlainText;color:root.muted;font.pixelSize:Style.space(10);font.bold:true;font.letterSpacing:1.5}
                Button{text:"↻";tooltipText:strings.t("refresh");fontSize:Style.space(17);onClicked:root.refresh()}
            }
            ColumnLayout {
                Layout.fillWidth:true;spacing:Style.space(13)
                Repeater {
                    model:root.library.recent||[]
                    delegate:RowLayout {
                        required property var modelData
                        Layout.fillWidth:true;spacing:Style.space(10)
                        Rectangle {
                            Layout.preferredWidth:Style.space(30);Layout.preferredHeight:Style.space(34);radius:Style.space(6);color:Qt.rgba(root.accent.r,root.accent.g,root.accent.b,.10)
                            Text{anchors.centerIn:parent;text:"≋";textFormat:Text.PlainText;color:root.accent;font.pixelSize:Style.space(22)}
                        }
                        ColumnLayout {
                            Layout.fillWidth:true;spacing:Style.space(3)
                            Text{Layout.fillWidth:true;text:root.hideTitles?strings.t("session"):Model.literal(modelData.title);textFormat:Text.PlainText;color:root.ink;elide:Text.ElideRight;font.pixelSize:Style.font.body;font.weight:Font.Medium}
                            Text {
                                text:Qt.locale(I18n.formatLocale).toString(new Date(modelData.startedAt),"ddd d MMM · HH:mm")
                                textFormat:Text.PlainText;color:root.muted;font.pixelSize:Style.font.bodySmall
                            }
                        }
                        ColumnLayout {
                            Layout.alignment:Qt.AlignRight;spacing:Style.space(3)
                            Text{Layout.alignment:Qt.AlignRight;text:Model.duration(modelData.durationMs);textFormat:Text.PlainText;color:root.muted;font.family:"monospace";font.pixelSize:Style.font.bodySmall}
                            Text{Layout.alignment:Qt.AlignRight;text:strings.t(modelData.transcriptionState==="error"?"failed":modelData.pending?"transcribing":"saved");textFormat:Text.PlainText;color:modelData.transcriptionState==="error"?"#fbbf24":root.muted;font.pixelSize:Style.space(10)}
                        }
                    }
                }
                Text{visible:!(root.library.recent||[]).length;Layout.fillWidth:true;text:strings.t(root.library.available?"empty":"library.unavailable");textFormat:Text.PlainText;color:root.muted;font.pixelSize:Style.font.body;wrapMode:Text.WordWrap}
            }
            // Navigation first; preferences and exit are separated from daily actions.
            RowLayout {
                Layout.fillWidth:true;spacing:Style.space(7)
                ToolbarButton {
                    kind:"library";label:strings.t("toolbar.library");description:strings.t("library")
                    onClicked:root.openApp()
                }
                ToolbarButton {
                    kind:"ask";label:strings.t("toolbar.ask");description:strings.t("ask")
                    enabled:!!root.roleEntries.ask && root.roleEntries.ask.enabled
                    onClicked:root.request("ask")
                }
                Item {Layout.fillWidth:true}
                Rectangle {Layout.preferredWidth:1;Layout.preferredHeight:Style.space(25);color:root.ink;opacity:.12}
                ToolbarButton {
                    kind:"settings";label:strings.t("toolbar.settings");description:strings.t("settings")
                    enabled:!!root.roleEntries.settings && root.roleEntries.settings.enabled
                    onClicked:root.request("settings")
                }
                ToolbarButton {
                    kind:"quit";label:strings.t("toolbar.quit");description:strings.t("quit");destructive:true
                    enabled:!!root.roleEntries.quit && root.roleEntries.quit.enabled
                    onClicked:{root.request("quit");root.dismiss()}
                }
            }
            Flow {
                visible:root.extraActions.length>0
                Layout.fillWidth:true;spacing:Style.space(7)
                Repeater {
                    model:root.extraActions
                    delegate:ToolbarButton {
                        required property var modelData
                        kind:"calendar";label:Model.literal(modelData.text,24);description:Model.literal(modelData.text)
                        enabled:modelData.enabled
                        onClicked:root.nativeAction(modelData)
                    }
                }
            }
            Rectangle{Layout.fillWidth:true;height:1;color:root.ink;opacity:.10}
            RowLayout {
                Layout.fillWidth:true;spacing:Style.space(7)
                Text{text:"◇";textFormat:Text.PlainText;color:root.accent;font.pixelSize:Style.font.bodySmall}
                Text{Layout.fillWidth:true;text:strings.t(root.hideTitles?"privacy.detail":"private");textFormat:Text.PlainText;color:root.muted;font.pixelSize:Style.font.bodySmall;wrapMode:Text.WordWrap}
            }
        }
    }
}
