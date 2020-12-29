/*
 * <one line to give the program's name and a brief idea of what it does.>
 * Copyright (C) 2019  eran <email>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
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

OrientationHelper {
	id: timedShootFeedback
	anchors.fill: parent

	function start() {
	}

	function stop() {
		remainingSecsLabel.text = "";
	}

	function showRemainingSecs(secs) {
		remainingSecsLabel.text = secs;
		remainingSecsLabel.opacity = 1.0;
		remainingSecsLabelAnimation.restart();
	}

	Label {
		id: remainingSecsLabel
		anchors.fill: parent
		font.pixelSize: units.gu(6)
		font.bold: true
		color: "white"
		style: Text.Outline;
		styleColor: "black"
		verticalAlignment: Text.AlignVCenter
		horizontalAlignment: Text.AlignHCenter
		visible: opacity != 0.0
		opacity: 0.0

		OpacityAnimator {
			id: remainingSecsLabelAnimation
			target: remainingSecsLabel
			from: 1.0
			to: 0.0
			duration: 750
			easing: UbuntuAnimation.StandardEasing
		}
	}

	// tapping anywhere on the screen while a timed shoot is ongoing cancels it
	MouseArea {
		anchors.fill: parent
		onClicked: viewFinderOverlay.controls.cancelTimedShoot()
		enabled: remainingSecsLabel.visible
	}
}
