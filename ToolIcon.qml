// SPDX-License-Identifier: MIT
import QtQuick

Canvas {
    id:root
    property string kind:"library"
    property color color:"#c4b5fd"
    implicitWidth:24
    implicitHeight:24
    antialiasing:true
    onKindChanged:requestPaint()
    onColorChanged:requestPaint()
    onWidthChanged:requestPaint()
    onHeightChanged:requestPaint()
    onPaint: {
        var c=getContext("2d")
        c.reset();c.scale(width/24,height/24)
        c.strokeStyle=root.color;c.fillStyle=root.color;c.lineWidth=1.7;c.lineCap="round";c.lineJoin="round"
        function line(x1,y1,x2,y2){c.moveTo(x1,y1);c.lineTo(x2,y2)}
        c.beginPath()
        if(kind==="library") {
            c.rect(3.5,4,4,16);c.rect(9.5,4,4,16)
            c.moveTo(16,5);c.lineTo(19.2,4.2);c.lineTo(22,19);c.lineTo(18.7,19.8);c.closePath()
            line(4,8,7,8);line(10,16,13,16)
        } else if(kind==="ask") {
            c.moveTo(14,5);c.lineTo(5,5);c.quadraticCurveTo(3,5,3,7);c.lineTo(3,14);c.quadraticCurveTo(3,16,5,16);c.lineTo(7,16);c.lineTo(7,20);c.lineTo(11,16);c.lineTo(18,16);c.quadraticCurveTo(20,16,20,14);c.lineTo(20,11)
            line(7,9,12,9);line(7,12,14,12)
            c.moveTo(18,1.8);c.lineTo(19.3,5);c.lineTo(22.5,6.3);c.lineTo(19.3,7.6);c.lineTo(18,10.8);c.lineTo(16.7,7.6);c.lineTo(13.5,6.3);c.lineTo(16.7,5);c.closePath()
        } else if(kind==="settings") {
            for(var i=0;i<24;i++) {var a=i*Math.PI/12-Math.PI/2;var r=(i%3===1)?7:9;var x=12+Math.cos(a)*r,y=12+Math.sin(a)*r;if(i===0)c.moveTo(x,y);else c.lineTo(x,y)}
            c.closePath();c.moveTo(15.2,12);c.arc(12,12,3.2,0,Math.PI*2)
        } else if(kind==="quit") {
            c.arc(12,13,7.5,-Math.PI/4,Math.PI*1.25);line(12,2.5,12,11)
        } else if(kind==="record") {c.arc(12,12,7.5,0,Math.PI*2);c.stroke();c.beginPath();c.arc(12,12,3,0,Math.PI*2);c.fill();return
        } else if(kind==="stop") {c.rect(5,5,14,14)
        } else if(kind==="pause") {c.rect(5.5,4,4,16);c.rect(14.5,4,4,16)
        } else if(kind==="play") {c.moveTo(7,4);c.lineTo(20,12);c.lineTo(7,20);c.closePath()
        } else if(kind==="calendar") {c.rect(3,5,18,16);line(7,2,7,8);line(17,2,17,8);line(3,10,21,10);line(7,14,10,14);line(14,14,17,14)
        } else {line(4,12,20,12);line(14,6,20,12);line(14,18,20,12)}
        c.stroke()
    }
}
