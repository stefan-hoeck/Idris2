class support_system_clock_OSClock {
    constructor(seconds, nanoseconds) {
        this.seconds = seconds
        this.nanoseconds = nanoseconds
    }
}

function support_system_clock_clockValid(clock) {
    return clock instanceof support_system_clock_OSClock
}

function support_system_clock_clockSecond(clock) {
    return clock.seconds
}

function support_system_clock_clockNanosecond(clock) {
    return clock.nanoseconds
}

function support_system_clock_clockUtc() {
    let ms = Date.now()
    let secs = ms / 1000
    let ns = (ms % 1000) / 1_000_000
    return new support_system_clock_OSClock(secs, ns)
}

function support_system_clock_clockProcess() {
    let us = process.cpuUsage().user 
    let secs = us / 1_000_000
    let ns = (us % 1_000_000) * 1000
    return new support_system_clock_OSClock(secs, ns)
}

function support_system_clock_clockMonotonic() {
    let [secs, ns] = process.hrtime()
    return new support_system_clock_OSClock(secs, ns)
}

function support_system_clock_clockGC() {
    return null
}

// JS is singlethreaded, so these are equivalent
let support_system_clock_clockThread = support_system_clock_clockProcess
