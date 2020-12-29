/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Thumbnailer 0.1
import Ubuntu.Content 1.3
import Qt.labs.settings 1.0
import CameraApp 0.1
import "MimeTypeMapper.js" as MimeTypeMapper

FocusScope {
    id: photogridView

    property var model
    signal photoClicked(int index)
    signal photoPressAndHold(int index)
    signal photoSelectionAreaClicked(int index)
    signal exitUserSelectionMode
    signal toggleHeader()
    property real headerHeight
    property bool inView
    property bool inSelectionMode
    property bool userSelectionMode: false
    property var actions: userSelectionMode ? userSelectionActions : regularModeActions
    property list<Action> userSelectionActions: [
        Action {
            text: i18n.tr("Share")
            iconName: "share"
            enabled: model.selectedFiles.length > 0
            onTriggered: {
                // Display a warning message if we are attempting to share mixed
                // content, as the framework does not properly support this
                if (selectionContainsMixedMedia()) {
                    PopupUtils.open(unableShareDialogComponent).parent = photogridView;
                } else {
                    PopupUtils.open(sharePopoverComponent).parent = photogridView;
                }
            }
        },
        Action {
            text: i18n.tr("Delete")
            iconName: "delete"
            onTriggered: {
                if (model.selectedFiles.length > 0) {
                    var dialog = PopupUtils.open(deleteDialogComponent)
                    dialog.parent = photogridView
                }
            }
        }
    ]

    property list<Action> regularModeActions: [
            Action {
                text: i18n.tr("Settings")
                objectName: "openSettingsPage"
                iconName: "settings"
                onTriggered: { 
                    galleryPageStack.clear();
                    galleryPageStack.push(advancedOptionsComponent); 
                }
            },
			Action {
                text: i18n.tr("About")
                objectName: "openAboutPage"
                iconName: "info"
                onTriggered: {
                    galleryPageStack.clear();
                    galleryPageStack.push(infoPageComponent);
                }
            }
    ]

    function selectionContainsMixedMedia() {
        var selection = model.selectedFiles;
        var lastType = model.get(selection[0], "fileType");
        for (var i = 1; i < selection.length; i++) {
            var type = model.get(selection[i], "fileType");
            if (type !== lastType) {
                return true;
            }
            lastType = type;
        }
        return false;
    }

    function showPhotoAtIndex(index) {
        gridView.positionViewAtIndex(index, GridView.Center);
    }

    function exit() {
    }

    Settings {
        id:galleryGridViewSettings
        property var delegateWidth: gridView.baseDelegateWidth
        property var delegateHeight: gridView.baseDelegateHeight
        property real currentScale: 1
    }

    PinchArea {
        id:galleryViewPinch
        anchors.fill: parent

        property real currentScale: galleryGridViewSettings.currentScale
        pinch.dragAxis: Pinch.NoDrag
        pinch.minimumScale: 0.5
        pinch.maximumScale: 1.5
        //FIXME  This is a a workaround that remember the scale between pinches
        pinch.target: Item {
          width: galleryGridViewSettings.delegateWidth
          height: galleryGridViewSettings.delegateHeight
          scale:galleryGridViewSettings.currentScale
          visible:false
        }

        onPinchUpdated: {
            if( pinch.scale ) {
                galleryGridViewSettings.currentScale = Math.min(2,Math.max(0.33,galleryViewPinch.pinch.target.scale))  ;
                galleryGridViewSettings.delegateHeight = Math.floor(gridView.baseDelegateHeight * currentScale);
                galleryGridViewSettings.delegateWidth =  Math.floor(gridView.baseDelegateWidth * currentScale);
            }
        }

        ResponsiveGridView {
            id: gridView
            anchors.fill: parent
            // FIXME: prevent the header from overlapping the beginning of the grid
            // when Qt 5.3 is landed, use property 'displayMarginBeginning' instead
            // cf. http://qt-project.org/doc/qt-5/qml-qtquick-gridview.html#displayMarginBeginning-prop
            header: Item {
                width: gridView.width
                height: headerHeight
            }

            property var baseDelegateWidth: Math.min(photogridView.width,photogridView.height)/2/2
            property var baseDelegateHeight: baseDelegateWidth

            Component.onCompleted: {
                // FIXME: workaround for qtubuntu not returning values depending on the grid unit definition
                // for Flickable.maximumFlickVelocity and Flickable.flickDeceleration
                var scaleFactor = units.gridUnit / 8;
                maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
                flickDeceleration = flickDeceleration * scaleFactor;
            }

            minimumHorizontalSpacing: units.dp(2)
            maximumNumberOfColumns: 100
            delegateWidth: galleryGridViewSettings.delegateWidth
            delegateHeight: galleryGridViewSettings.delegateHeight
            StateSaver.properties:"delegateWidth,delegateHeight"

            model: photogridView.model
            delegate: Item {
                z:10
                id: cellDelegate
                objectName: "mediaItem" + index

                width: gridView.cellWidth
                height: gridView.cellHeight

                Behavior on height { UbuntuNumberAnimation {} }
                Behavior on width { UbuntuNumberAnimation {} }

                property bool isVideo: MimeTypeMapper.mimeTypeToContentType(fileType) === ContentType.Videos

                Image {
                    id: thumbnail
                    property real margin: units.dp(2)
                    anchors {
                        top: parent.top
                        topMargin: index < photogridView.columns ? 0 : margin/2
                        bottom: parent.bottom
                        bottomMargin: margin/2
                        left: parent.left
                        leftMargin: index % photogridView.columns == 0 ? 0 : margin/2
                        right: parent.right
                        rightMargin: index % photogridView.columns == photogridView.columns - 1 ? 0 : margin/2
                    }

                    asynchronous: true
                    cache: photogridView.inView
                    // The thumbnailer does not seem to check when an image has been changed on disk,
                    // so we use this hack to force it to check and refresh if necessary.
                    source: photogridView.inView ? "image://thumbnailer/" + fileURL.toString() + "?at=" + Date.now() : ""
                    sourceSize {
                        width: gridView.baseDelegateWidth
                        height: gridView.baseDelegateHeight
                    }
                    fillMode: Image.PreserveAspectCrop
                    opacity: status == Image.Ready ? 1.0 : 0.0
                    Behavior on opacity { UbuntuNumberAnimation {duration: UbuntuAnimation.FastDuration} }
                }

                Icon {
                    width: units.gu(3)
                    height: units.gu(3)
                    anchors.centerIn: parent
                    name: "media-playback-start"
                    color: "white"
                    opacity: 0.8
                    visible: isVideo
                    asynchronous: true
                }

                Icon {
                    objectName: "thumbnailLoadingErrorIcon"
                    anchors.centerIn: parent
                    width: units.gu(6)
                    height: width
                    name: cellDelegate.isVideo ? "stock_video" : "stock_image"
                    color: "white"
                    opacity: thumbnail.status == Image.Error ? 1.0 : 0.0
                    asynchronous: true
                 }

                MouseArea {
                    anchors.fill: parent
                    onClicked: photogridView.photoClicked(index)
                    onPressAndHold: photogridView.photoPressAndHold(index)
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: units.gu(0.5)
                        rightMargin: units.gu(0.5)
                    }
                    width: units.gu(4)
                    height: units.gu(4)
                    color: selected ? theme.palette.normal.positive : UbuntuColors.inkstone
                    radius: 10
                    opacity: selected ? 0.8 : 0.6
                    visible: inSelectionMode

                    Icon {
                        objectName: "mediaItemCheckBox"
                        anchors.centerIn: parent
                        width: parent.width * 0.8
                        height: parent.height * 0.8
                        name: "ok"
                        color: "white"
                        visible: selected
                        asynchronous: true
                    }

                }

                MouseArea {
                    anchors {
                        top: parent.top
                        right: parent.right
                    }
                    width: parent.width * 0.5
                    height: parent.height * 0.5
                    enabled: inSelectionMode

                    onClicked: {
                        mouse.accepted = true;
                        photogridView.photoSelectionAreaClicked(index)
                    }
                }
            }
        }
    }

    Component {
        id: contentItemComp
        ContentItem {}
    }

    Component {
        id: sharePopoverComponent

        SharePopover {
            id: sharePopover

            onContentPeerSelected: photogridView.exitUserSelectionMode();
            onVisibleChanged: photogridView.toggleHeader()

            transferContentType: MimeTypeMapper.mimeTypeToContentType(model.get(model.selectedFiles[0], "fileType"));
            transferItems: model.selectedFiles.map(function(row) {
                             return contentItemComp.createObject(parent, {"url": model.get(row, "filePath")});
                           })
        }
    }

    Component {
        id: deleteDialogComponent

        DeleteDialog {
            id: deleteDialog

            FileOperations {
                id: fileOperations
            }

            onDeleteFiles: {
                model.deleteSelectedFiles();
                photogridView.exitUserSelectionMode();
            }
            onVisibleChanged: photogridView.toggleHeader()
        }
    }

    Component {
        id: unableShareDialogComponent
        UnableShareDialog {
            objectName: "unableShareDialog"
            onVisibleChanged: photogridView.toggleHeader()
        }
    }

}
