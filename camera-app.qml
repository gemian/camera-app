import QtQuick 2.0
import QtMultimedia 5.0

Rectangle {
    id: main
    width: 400
    height: 600
    color: "black"

    Camera {
        id: camera
        flash.mode: Camera.FlashOff

        /* Use only digital zoom for now as it's what phone cameras mostly use.
           TODO: if optical zoom is available, maximumZoom should be the combined
           range of optical and digital zoom and currentZoom should adjust the two
           transparently based on the value. */
        property alias currentZoom: camera.digitalZoom
        property alias maximumZoom: camera.maximumDigitalZoom
    }

    VideoOutput {
        anchors.fill: parent
        source: camera

        MouseArea {
            anchors.fill: parent
            onClicked: {
                toolbar.opacity = 1.0;
                ring.x = mouse.x - ring.width * 0.5;
                ring.y = mouse.y - ring.height * 0.5;
                ring.opacity = 1.0;
                zoomControl.opacity = 0.0
                // TODO: call the spot focusing API here
            }
        }

        FocusRing {
            id: ring
            opacity: 0.0
            onClicked: camera.takeSnapshot()
        }

        ZoomControl {
            id: zoomControl
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            opacity: 0.0

            maximumValue: camera.maximumZoom
            onValueChanged: {
                hideZoom.restart();
                camera.currentZoom = value;
            }
        }

//        onIsRecordingChanged: if (isRecording) ring.opacity = 0.0
//        onSnapshotSuccess: {
//            snapshot.source = imagePath
//            console.log("snapshot successfully taken");
//            ring.opacity = 0.0
//            toolbar.opacity = 0.0
//        }
    }

    Snapshot {
        id: snapshot
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: 0
    }

    Toolbar {
        id: toolbar
        anchors.fill: parent
        camera: camera
        opacity: 0.0
        onZoomClicked: {
            zoomControl.opacity = 1.0;
            toolbar.opacity = 0.0;
            ring.opacity = 0.0;
        }

        Timer {
            id: hideZoom
            interval: 5000
            onTriggered: zoomControl.opacity = 0.0;
        }
    }
}
