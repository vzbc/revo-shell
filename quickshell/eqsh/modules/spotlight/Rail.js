.pragma library

// Damped-response motion for the spotlight mode rail.
// progress is railProgress in [0, 1]; index is the circle index (0..3).

var travelDelays = [0.06, 0.036, 0.032];
var travelDecays = [7.2, 5.4, 5.4];
var travelFrequencies = [8.9, 6.2, 5.35];
var growthRates = [3.8, 3.1, 2.7];

function smoothstep(value) {
    var p = Math.max(0, Math.min(1, value));
    return p * p * (3 - 2 * p);
}

function stage(progress, start, end) {
    return smoothstep((progress - start) / (end - start));
}

// Normalized damped response so reversal stays a pure function of progress
// and the final layout is exact.
function response(progress, delay, decay, frequency, phase) {
    var time = Math.max(0, Math.min(1, progress) - delay);
    var end = 1 - delay;
    var value = 1 - Math.exp(-decay * time) * (Math.cos(frequency * time) + phase * Math.sin(frequency * time));
    var terminal = 1 - Math.exp(-decay * end) * (Math.cos(frequency * end) + phase * Math.sin(frequency * end));
    if (Math.abs(terminal) < 1e-6) return 0;
    return value / terminal;
}

// The pill leads the motion.
function pill(progress) {
    return response(progress, 0, 6.2, 7.5, 0.4);
}

function growth(progress, index) {
    if (index === 0) return response(progress, 0.055, 10.5, 10.5, 1);
    var rate = growthRates[index - 1];
    return response(progress, 0, rate, rate, 0);
}

// Trailing circles follow with progressively slower responses.
function travel(progress, index) {
    if (index === 0) return 1;
    var i = index - 1;
    var decay = travelDecays[i];
    var frequency = travelFrequencies[i];
    return response(progress, travelDelays[i], decay, frequency, decay / frequency);
}

function emergence(progress) {
    return growth(progress, 0);
}

function iconAlpha(progress, index) {
    return stage(progress, 0.36 + index * 0.025, 0.55 + index * 0.025);
}
