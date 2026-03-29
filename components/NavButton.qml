import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Button {
    property string iconSource: ""
    property int targetIndex: 0
    property int currentIndex: 0

    Layout.fillWidth: true
    Layout.preferredHeight: 50

    background: Rectangle {
        color: currentIndex === targetIndex ? "#34495e" : (parent.hovered ? "#3e5a6f" : "transparent")
        radius: 6
        Rectangle {
            width: 4; height: 20
            color: "#3498db"
            anchors.verticalCenter: parent.verticalCenter
            visible: currentIndex === targetIndex
        }
    }

    contentItem: RowLayout {
        spacing: 15
        Item { width: 10 }
        Image {
            source: iconSource
            sourceSize: Qt.size(20, 20)
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            opacity: currentIndex === targetIndex ? 1.0 : 0.7
        }
        Text {
            text: parent.parent.text
            color: "white"
            font.pixelSize: 14
            font.bold: currentIndex === targetIndex
            Layout.fillWidth: true
        }
    }
}
