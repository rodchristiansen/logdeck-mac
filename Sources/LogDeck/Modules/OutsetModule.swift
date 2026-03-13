import Foundation

struct OutsetModule: ToolModule {
    let id = "outset"
    let name = "Outset"
    let icon = "terminal"
    let category = ToolCategory.scripting

    let detectionPaths = [
        "/usr/local/outset/outset"
    ]

    let logSources = [
        LogSource(
            id: "outset-root",
            label: "Root Log",
            path: "/var/log/outset.log",
            requiresPrivilege: true
        ),
        LogSource(
            id: "outset-user",
            label: "User Log",
            path: "~/Library/Logs/outset.log"
        )
    ]

    let supportPaths = [
        SupportPath(
            id: "outset-login-every",
            label: "Login Every Scripts",
            path: "/usr/local/outset/login-every",
            kind: .scripts
        ),
        SupportPath(
            id: "outset-login-once",
            label: "Login Once Scripts",
            path: "/usr/local/outset/login-once",
            kind: .scripts
        ),
        SupportPath(
            id: "outset-login-priv-every",
            label: "Login Privileged Every",
            path: "/usr/local/outset/login-privileged-every",
            kind: .scripts
        ),
        SupportPath(
            id: "outset-login-priv-once",
            label: "Login Privileged Once",
            path: "/usr/local/outset/login-privileged-once",
            kind: .scripts
        ),
        SupportPath(
            id: "outset-boot-every",
            label: "Boot Every Scripts",
            path: "/usr/local/outset/boot-every",
            kind: .scripts
        ),
        SupportPath(
            id: "outset-boot-once",
            label: "Boot Once Scripts",
            path: "/usr/local/outset/boot-once",
            kind: .scripts
        ),
        SupportPath(
            id: "outset-on-demand",
            label: "On Demand Scripts",
            path: "/usr/local/outset/on-demand",
            kind: .scripts
        )
    ]
}
