/* ===============================================================================================================================================
   makeCrosshairGuides

   Description
   This script makes crosshair guides on the selected anchor points and handles.

   Usage
   1. Select some anchor points with the Direct Selection Tool, run this script from File > Scripts > Other Script...
   2. Select the position where you want to draw the guide.
   3. Select the axis of the guide.

   Notes
   Draw guides to the edge of the artboard.
   In rare cases, the script may not work if you continue to use it.
   In this case, restart Illustrator and try again.

   Requirements
   Illustrator CS4 or higher

   Version
   1.0.0

   Homepage
   github.com/sky-chaser-high/adobe-illustrator-scripts

   License
   Released under the MIT license.
   https://opensource.org/licenses/mit-license.php
   =============================================================================================================================================== */

(function() {
    if (app.documents.length && isValidVersion()) main();
})();


function main() {
    var items = app.activeDocument.selection;
    var shapes = getPathItems(items);
    var points = getSelectedAnchorPoints(shapes);
    if (!points.length) return;

    var dialog = showDialog();

    dialog.ok.onClick = function() {
        var position = {
            isAnchor: dialog.anchor.value,
            isHandle: dialog.handle.value
        };
        var axis = {
            isX: dialog.horizontal.value,
            isY: dialog.vertical.value
        };
        for (var i = 0; i < points.length; i++) {
            var point = points[i];
            createCrosshairGuide(point, position, axis);
        }
        dialog.close();
    }

    dialog.show();
}


function createCrosshairGuide(point, position, axis) {
    var bounds = getBounds(point);
    if (position.isAnchor) {
        drawCrosshairLine(point.anchor, bounds, axis);
    }
    if (position.isHandle) {
        if (hasHandle(point.anchor, point.leftDirection)) {
            drawCrosshairLine(point.leftDirection, bounds, axis);
        }
        if (hasHandle(point.anchor, point.rightDirection)) {
            drawCrosshairLine(point.rightDirection, bounds, axis);
        }
    }
}


function drawCrosshairLine(point, bounds, axis) {
    var x = 0;
    var y = 1;

    var horizontal = [
        [bounds.x1, point[y]],
        [bounds.x2, point[y]]
    ];
    if (axis.isX) drawLine(horizontal);

    var vertical = [
        [point[x], bounds.y1],
        [point[x], bounds.y2]
    ];
    if (axis.isY) drawLine(vertical);
}


function drawLine(points) {
    var layer = app.activeDocument.activeLayer;
    var line = layer.pathItems.add();
    line.setEntirePath(points);
    line.guides = true;
    line.filled = false;
    line.stroked = false;
}


function getBounds(point) {
    var index = getArtboardIndex(point.anchor);
    if (index == undefined) {
        return getShapeBounds(point);
    }
    else {
        return getArtboardBounds(index);
    }
}


function getShapeBounds(point) {
    var shape = point.parent;
    var bounds = shape.geometricBounds;
    var width = bounds[2] - bounds[0];
    var height = bounds[1] - bounds[3];
    return {
        x1: bounds[0] - width,
        y1: bounds[1] + height,
        x2: bounds[2] + width,
        y2: bounds[3] - height
    };
}


function getArtboardBounds(index) {
    var artboard = app.activeDocument.artboards[index];
    var bounds = artboard.artboardRect;
    return {
        x1: bounds[0],
        y1: bounds[1],
        x2: bounds[2],
        y2: bounds[3]
    };
}


function getArtboardIndex(point) {
    var artboards = app.activeDocument.artboards;
    for (var i = 0; i < artboards.length; i++) {
        var bounds = artboards[i].artboardRect;
        if (!isInsideArea(point, bounds)) continue;
        return i;
    }
}


function isInsideArea(point, bounds) {
    var x = 0;
    var y = 1;
    var x1 = bounds[0];
    var y1 = bounds[1];
    var x2 = bounds[2];
    var y2 = bounds[3];
    return x1 <= point[x] && point[x] <= x2 && y2 <= point[y] && point[y] <= y1;
}


function isSamePosition(anchor, handle) {
    return anchor == handle;
}


function hasHandle(anchor, handle) {
    var x = 0;
    var y = 1;
    return anchor[x] != handle[x] || anchor[y] != handle[y];
}


function getSelectedAnchorPoints(shapes) {
    var ANCHOR = PathPointSelection.ANCHORPOINT;
    var anchors = [];
    for (var i = 0; i < shapes.length; i++) {
        var points = shapes[i].pathPoints;
        for (var j = 0; j < points.length; j++) {
            var point = points[j];
            if (point.selected != ANCHOR) continue;
            anchors.push(point);
        }
    }
    return anchors;
}


function getPathItems(items) {
    var shapes = [];
    for (var i = 0; i < items.length; i++) {
        var item = items[i];
        if (item.typename == 'PathItem') {
            shapes.push(item);
        }
        if (item.typename == 'GroupItem') {
            shapes = shapes.concat(getPathItems(item.pageItems));
        }
        if (item.typename == 'CompoundPathItem') {
            shapes = shapes.concat(getPathItems(item.pathItems));
        }
    }
    return shapes;
}


function isValidVersion() {
    var cs4 = 14;
    var current = parseInt(app.version);
    if (current < cs4) return false;
    return true;
}


function showDialog() {
    $.localize = true;
    var ui = localizeUI();

    var dialog = new Window('dialog');
    dialog.text = ui.title;
    dialog.orientation = 'column';
    dialog.alignChildren = ['fill', 'top'];
    dialog.spacing = 10;
    dialog.margins = 16;

    var panel1 = dialog.add('panel', undefined, undefined, { name: 'panel1' });
    panel1.text = ui.position;
    panel1.orientation = 'column';
    panel1.alignChildren = ['left', 'top'];
    panel1.spacing = 10;
    panel1.margins = 10;

    var group1 = panel1.add('group', undefined, { name: 'group1' });
    group1.orientation = 'column';
    group1.alignChildren = ['left', 'center'];
    group1.spacing = 10;
    group1.margins = [0, 8, 0, 0];

    var checkbox1 = group1.add('checkbox', undefined, undefined, { name: 'checkbox1' });
    checkbox1.text = ui.anchor;
    checkbox1.value = true;

    var checkbox2 = group1.add('checkbox', undefined, undefined, { name: 'checkbox2' });
    checkbox2.text = ui.handle;

    var panel2 = dialog.add('panel', undefined, undefined, { name: 'panel2' });
    panel2.text = ui.axis;
    panel2.orientation = 'column';
    panel2.alignChildren = ['left', 'top'];
    panel2.spacing = 10;
    panel2.margins = 10;

    var group2 = panel2.add('group', undefined, { name: 'group2' });
    group2.orientation = 'column';
    group2.alignChildren = ['left', 'center'];
    group2.spacing = 10;
    group2.margins = [0, 8, 0, 0];

    var checkbox3 = group2.add('checkbox', undefined, undefined, { name: 'checkbox3' });
    checkbox3.text = ui.horizontal;
    checkbox3.value = true;

    var checkbox4 = group2.add('checkbox', undefined, undefined, { name: 'checkbox4' });
    checkbox4.text = ui.vertical;
    checkbox4.value = true;

    var group3 = dialog.add('group', undefined, { name: 'group3' });
    group3.orientation = 'row';
    group3.alignChildren = ['left', 'center'];
    group3.spacing = 10;
    group3.margins = 0;

    var button1 = group3.add('button', undefined, undefined, { name: 'Cancel' });
    button1.text = ui.cancel;
    button1.preferredSize.width = 90;

    var button2 = group3.add('button', undefined, undefined, { name: 'OK' });
    button2.text = ui.ok;
    button2.preferredSize.width = 90;

    dialog.anchor = checkbox1;
    dialog.handle = checkbox2;
    dialog.horizontal = checkbox3;
    dialog.vertical = checkbox4;
    dialog.ok = button2;
    return dialog;
}


function localizeUI() {
    return {
        title: {
            en: 'Make Crosshair Guides',
            ja: '十字ガイドを作成'
        },
        position: {
            en: 'Position',
            ja: '位置'
        },
        anchor: {
            en: 'Anchor Point',
            ja: 'アンカーポイント'
        },
        handle: {
            en: 'Handle',
            ja: 'ハンドル'
        },
        axis: {
            en: 'Axis',
            ja: '方向'
        },
        horizontal: {
            en: 'Horizontal',
            ja: '水平方向'
        },
        vertical: {
            en: 'Vertical',
            ja: '垂直方向'
        },
        cancel: {
            en: 'Cancel',
            ja: 'キャンセル'
        },
        ok: {
            en: 'OK',
            ja: 'OK'
        }
    };
}
