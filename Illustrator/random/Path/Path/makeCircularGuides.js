/* ===============================================================================================================================================
   makeCircularGuides

   Description
   This script makes circular guides on the selected anchor points.

   Usage
   1. Select some anchor points with the Direct Selection Tool, run this script from File > Scripts > Other Script...
   2. Enter a radius. If you want to draw multiple circles, enter the radiuses separated by commas.
   3. If you want to draw a circle using the length of the handle, check the Use Handle Length checkbox.

   Notes
   The units of the radius depend on the ruler units.
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
        var config = getConfiguration(dialog);
        createCircularGuide(points, config.radiuses, config.useHandleLength);
        dialog.close();
    }

    dialog.show();
}


function getConfiguration(dialog) {
    var radiuses = [];
    var units = dialog.units;
    var values = dialog.radius.text.split(/,\s*/g);
    for (var i = 0; i < values.length; i++) {
        var value = getValue(values[i]);
        if (!value) continue;
        var radius = convertUnits(value + units, 'pt');
        radiuses.push(radius);
    }
    return {
        radiuses: radiuses,
        useHandleLength: dialog.handle.value
    };
}


function createCircularGuide(points, radiuses, isHandle) {
    for (var i = 0; i < points.length; i++) {
        var point = points[i];
        if (isHandle) {
            createGuidesWithHandleLength(point);
        }
        else {
            createGuides(point, radiuses);
        }
    }
}


function createGuidesWithHandleLength(point) {
    if (hasHandle(point.anchor, point.leftDirection)) {
        var radius = getHandleLength(point.anchor, point.leftDirection);
        drawCircle(point.anchor, radius);
    }
    if (isSameHandleLength(point)) return;
    if (hasHandle(point.anchor, point.rightDirection)) {
        var radius = getHandleLength(point.anchor, point.rightDirection);
        drawCircle(point.anchor, radius);
    }
}


function createGuides(point, radiuses) {
    for (var i = 0; i < radiuses.length; i++) {
        var radius = radiuses[i];
        drawCircle(point.anchor, radius);
    }
}


function drawCircle(point, radius) {
    var x = 0;
    var y = 1;
    var diameter = radius * 2;
    var top = point[y] + radius;
    var left = point[x] - radius;
    var layer = app.activeDocument.activeLayer;
    var circle = layer.pathItems.ellipse(top, left, diameter, diameter);
    circle.guides = true;
    circle.filled = false;
    circle.stroked = false;
}


function getHandleLength(anchor, handle) {
    var x = 0;
    var y = 1;
    var width = handle[x] - anchor[x];
    var height = handle[y] - anchor[y];
    var sq = 2;
    return Math.sqrt(Math.pow(width, sq) + Math.pow(height, sq));
}


function isSameHandleLength(point) {
    var left = getHandleLength(point.anchor, point.leftDirection);
    var right = getHandleLength(point.anchor, point.rightDirection);
    return left == right;
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


function getValue(text) {
    var twoByteChar = /[！-～]/g;
    var value = text.replace(twoByteChar, function(str) {
        return String.fromCharCode(str.charCodeAt(0) - 0xFEE0);
    });
    if (isNaN(value) || !value) return 0;
    return Number(value);
}


function convertUnits(value, unit) {
    try {
        return Number(UnitValue(value).as(unit));
    }
    catch (err) {
        return Number(UnitValue('0pt').as('pt'));
    }
}


function getRulerUnits() {
    var unit = getUnitSymbol();
    if (!app.documents.length) return unit.pt;

    var document = app.activeDocument;
    var src = document.fullName;
    var ruler = document.rulerUnits;
    try {
        switch (ruler) {
            case RulerUnits.Pixels: return unit.px;
            case RulerUnits.Points: return unit.pt;
            case RulerUnits.Picas: return unit.pc;
            case RulerUnits.Inches: return unit.inch;
            case RulerUnits.Millimeters: return unit.mm;
            case RulerUnits.Centimeters: return unit.cm;

            case RulerUnits.Feet: return unit.ft;
            case RulerUnits.Yards: return unit.yd;
            case RulerUnits.Meters: return unit.meter;
        }
    }
    catch (err) {
        switch (xmpRulerUnits(src)) {
            case 'Feet': return unit.ft;
            case 'Yards': return unit.yd;
            case 'Meters': return unit.meter;
        }
    }
    return unit.pt;
}


function xmpRulerUnits(src) {
    if (!ExternalObject.AdobeXMPScript) {
        ExternalObject.AdobeXMPScript = new ExternalObject('lib:AdobeXMPScript');
    }
    var xmpFile = new XMPFile(src.fsName, XMPConst.FILE_UNKNOWN, XMPConst.OPEN_FOR_READ);
    var xmpPackets = xmpFile.getXMP();
    var xmp = new XMPMeta(xmpPackets.serialize());

    var namespace = 'http://ns.adobe.com/xap/1.0/t/pg/';
    var prop = 'xmpTPg:MaxPageSize';
    var unit = prop + '/stDim:unit';

    var ruler = xmp.getProperty(namespace, unit).value;
    return ruler;
}


function getUnitSymbol() {
    return {
        px: 'px',
        pt: 'pt',
        pc: 'pc',
        inch: 'in',
        ft: 'ft',
        yd: 'yd',
        mm: 'mm',
        cm: 'cm',
        meter: 'm'
    };
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
    var units = getRulerUnits();

    var dialog = new Window('dialog');
    dialog.text = ui.title;
    dialog.orientation = 'column';
    dialog.alignChildren = ['fill', 'top'];
    dialog.spacing = 10;
    dialog.margins = 16;

    var group1 = dialog.add('group', undefined, { name: 'group1' });
    group1.orientation = 'row';
    group1.alignChildren = ['left', 'center'];
    group1.spacing = 10;
    group1.margins = 0;

    var statictext1 = group1.add('statictext', undefined, undefined, { name: 'statictext1' });
    statictext1.text = ui.radius;

    var edittext1 = group1.add('edittext', undefined, undefined, { name: 'edittext1' });
    edittext1.text = '10';
    edittext1.preferredSize.width = 140;
    edittext1.active = true;

    var statictext2 = group1.add('statictext', undefined, undefined, { name: 'statictext2' });
    statictext2.text = units;

    var group2 = dialog.add('group', undefined, { name: 'group2' });
    group2.orientation = 'row';
    group2.alignChildren = ['left', 'center'];
    group2.spacing = 10;
    group2.margins = 0;

    var checkbox1 = group2.add('checkbox', undefined, undefined, { name: 'checkbox1' });
    checkbox1.text = ui.handle;

    var group3 = dialog.add('group', undefined, { name: 'group3' });
    group3.orientation = 'row';
    group3.alignChildren = ['right', 'center'];
    group3.spacing = 10;
    group3.margins = [0, 8, 0, 0];

    var button1 = group3.add('button', undefined, undefined, { name: 'Cancel' });
    button1.text = ui.cancel;
    button1.preferredSize.width = 90;

    var button2 = group3.add('button', undefined, undefined, { name: 'OK' });
    button2.text = ui.ok;
    button2.preferredSize.width = 90;

    statictext1.addEventListener('click', function() {
        edittext1.active = false;
        edittext1.active = true;
    });

    checkbox1.onClick = function() {
        if (this.value) {
            group1.enabled = false;
        }
        else {
            group1.enabled = true;
            edittext1.active = false;
            edittext1.active = true;
        }
    }

    dialog.radius = edittext1;
    dialog.handle = checkbox1;
    dialog.units = units;
    dialog.ok = button2;
    return dialog;
}


function localizeUI() {
    return {
        title: {
            en: 'Make Circular Guides',
            ja: '円形ガイドを作成'
        },
        radius: {
            en: 'Radius:',
            ja: '半径:'
        },
        handle: {
            en: 'Use Handle Length',
            ja: 'ハンドルの長さを使用'
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
