//
//  CreatePlugin.swift
//  
//
//  Created by Pavel Kasila on 3.04.22.
//

import Fluent

struct CreatePlugin: AsyncMigration {
    func prepare(on database: Database) async throws {
        let managementType = try await database.enum("release_management_type")
            .case("gh_releases")
            .case("codeedit")
            .create()

        let sdkType = try await database.enum("sdk_type")
            .case("swift")
            .case("js")
            .case("jsx")
            .create()

        try await database.schema("plugins")
            .id()
            .field("manifest", .dictionary, .required)
            .field("release_management", managementType, .required)
            .field("sdk", sdkType, .required)
            .field("author", .uuid)
            .field("ban", .dictionary)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("plugins").delete()
        try await database.enum("release_management_type").delete()
        try await database.enum("sdk_type").delete()
    }
}
