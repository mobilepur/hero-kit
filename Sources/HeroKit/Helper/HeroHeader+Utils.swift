import Foundation
import ObjectiveC
import os

func heroWarning(_ message: String) {
    #if DEBUG
        os_log(
            .fault,
            log: OSLog(subsystem: "com.apple.runtime-issues", category: "HeroKit"),
            "%{public}s",
            message
        )
    #endif
}
