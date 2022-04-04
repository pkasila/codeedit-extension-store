//
//  CreatePluginHookInfo.swift
//  
//
//  Created by Pavel Kasila on 3.04.22.
//

import Fluent

struct CreatePluginHookInfo: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("plugin_hooks")
            .id()
            .field("plugin_id", .uuid, .required, .references("plugins", "id"))
            .field("secret_data", .data, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("plugin_hooks").delete()
    }
}
