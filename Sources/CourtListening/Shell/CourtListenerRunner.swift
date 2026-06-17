import Foundation
import CourtListeningCore

/// The imperative shell. Holds mutable state, executes commands concurrently,
/// and feeds response messages back into the pure update function.
public actor CourtListenerRunner {
    public private(set) var model: CourtListenerModel
    let transport: any HTTPTransport
    let token: APIToken

    public init(token: APIToken, transport: (any HTTPTransport)? = nil) {
        self.model = .initial
        self.token = token
        self.transport = transport ?? CourtListenerTransport.live
    }

    public func handle(message: CourtListenerMessage) async {
        let (newModel, commands) = update(message: message, model: model)
        model = newModel
        await withTaskGroup(of: CourtListenerMessage?.self) { group in
            for command in commands {
                group.addTask { await self.execute(command) }
            }
            for await response in group {
                if let response {
                    await handle(message: response)
                }
            }
        }
    }
}
