// SPDX-License-Identifier: MIT
pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import qs.Ui as Ui
import "Model.js" as Model

Ui.Button {
    id:root
    property string kind:"library"
    property string label:""
    property string description:label
    property bool destructive:false
    implicitWidth:Style.space(65)
    implicitHeight:Style.space(66)
    text:""
    focusable:true
    foreground:destructive?"#e8a0ad":"#c4b5fd"
    background:Qt.rgba(foreground.r,foreground.g,foreground.b,destructive?.025:.045)
    bordered:false
    tooltipText:Model.tooltipText(description)
    Accessible.role:Accessible.Button
    Accessible.name:label
    Accessible.description:Model.literal(description)
    opacity:enabled?1:.35
    Column {
        anchors.centerIn:parent;spacing:Style.space(7)
        ToolIcon {anchors.horizontalCenter:parent.horizontalCenter;width:Style.space(22);height:width;kind:root.kind;color:root.foreground}
        Text {
            anchors.horizontalCenter:parent.horizontalCenter
            width:root.width-Style.space(6)
            text:root.label;textFormat:Text.PlainText
            color:Color.foreground;font.pixelSize:Style.space(10.5)
            horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight
        }
    }
}
