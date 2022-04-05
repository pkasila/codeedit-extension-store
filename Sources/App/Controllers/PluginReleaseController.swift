//
//  File.swift
//  
//
//  Created by Pavel Kasila on 5.04.22.
//

import Fluent
import Vapor

struct PluginReleaseController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let releases = routes.grouped("releases")

        // anyone
        releases.group(":releaseID") { release in
            release.get(use: get)
        }
    }

    func get(req: Request) async throws -> PluginRelease {
        guard let release = try await PluginRelease.find(req.parameters.get("releaseID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return release
    }
}
