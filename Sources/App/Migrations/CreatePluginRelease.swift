//
//  CreatePluginRelease.swift
//  
//
//  Created by Pavel Kasila on 3.04.22.
//

import Fluent

struct CreatePluginRelease: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("plugin_releases")
            .id()
            .field("plugin_id", .uuid, .required, .references("plugins", "id"))
            .field("external_id", .string, .required)
            .field("version", .string, .required)
            .field("tarball", .json)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("plugin_releases").delete()
    }
}
