pragma ComponentBehavior: Bound

import QtQuick

// Pure typewriter state machine - no visuals, no concept of time.
// The caller feeds character arrays via animateTo(), this object manages
// the delete-then-retype transition and exposes state for the skin to render.
//
// Public API:
//   model               - ListModel, bind your Repeater.model here
//   animState           - 0 IDLE | 1 DELETING | 2 TYPING | 3 DELETED (paused)
//   cursor              - index of the typing frontier
//   cursorOn            - blink phase (true = visible)
//   cursorVisible       - convenience: state==2 && frontier not past end
//   animateTo(chars[], pauseAfterDelete) - transition to a new character array
//                         if pauseAfterDelete is true, emits deletePhaseComplete
//                         and waits for resumeTyping() before typing begins
//   resumeTyping()      - continue from the DELETED (3) pause state
//   snapTo(chars[])     - instant swap, no animation
//
// Signals:
//   deletePhaseComplete - fired when the delete phase finishes (state -> 3)
//   typePhaseComplete   - fired when the type phase finishes (state -> 0)
Item {
    id: root

    readonly property var model: _slotsModel
    readonly property int animState: _state
    readonly property int cursor: _cursor
    readonly property bool cursorOn: _cursorOn
    readonly property bool cursorVisible: _state === 2 && _cursor < _target.length

    signal deletePhaseComplete
    signal typePhaseComplete

    function animateTo(newTarget, pauseAfterDelete, forceFullDelete) {
        _pauseAfterDelete = pauseAfterDelete === true;
        if (_state !== 0) {
            // Snap to the in-flight target so we diff from a clean slate
            _state = 0;
            _slotsModel.clear();
            for (var j = 0; j < _target.length; j++)
                _slotsModel.append({
                    ch: _target[j]
                });
        }
        var from = 0;
        if (!forceFullDelete) {
            var old = _currentChars();
            var minLen = Math.min(old.length, newTarget.length);
            from = minLen;
            for (var i = 0; i < minLen; i++) {
                if (old[i] !== newTarget[i]) {
                    from = i;
                    break;
                }
            }
            if (from === old.length && old.length === newTarget.length)
                return;
        }
        _target = newTarget;
        _from = from;
        if (_slotsModel.count > from) {
            _state = 1;
        } else {
            _cursor = from;
            if (_pauseAfterDelete) {
                _state = 3;
                root.deletePhaseComplete();
            } else {
                _state = 2;
            }
        }
    }

    function resumeTyping() {
        if (_state === 3)
            _state = 2;
    }

    function snapTo(chars) {
        _state = 0;
        _slotsModel.clear();
        for (var i = 0; i < chars.length; i++)
            _slotsModel.append({
                ch: chars[i]
            });
        _target = chars;
    }

    property int _state: 0
    property var _target: []
    property int _from: 0
    property int _cursor: 0
    property bool _cursorOn: true
    property bool _pauseAfterDelete: false

    function _currentChars() {
        var arr = [];
        for (var i = 0; i < _slotsModel.count; i++)
            arr.push(_slotsModel.get(i).ch);
        return arr;
    }

    function _step() {
        if (_state === 1) {
            _slotsModel.remove(_slotsModel.count - 1);
            if (_slotsModel.count <= _from) {
                _cursor = _from;
                if (_pauseAfterDelete) {
                    _state = 3;
                    root.deletePhaseComplete();
                } else {
                    _state = 2;
                }
            }
        } else if (_state === 2) {
            if (_cursor < _target.length) {
                _slotsModel.append({
                    ch: _target[_cursor]
                });
                _cursor++;
            } else {
                _state = 0;
                root.typePhaseComplete();
            }
        }
    }

    ListModel {
        id: _slotsModel
    }

    Timer {
        interval: 100
        repeat: true
        running: root._state === 1 || root._state === 2
        onTriggered: root._step()
    }

    Timer {
        interval: 450
        repeat: true
        running: root._state === 2
        onTriggered: root._cursorOn = !root._cursorOn
        onRunningChanged: if (!running)
            root._cursorOn = true
    }
}
