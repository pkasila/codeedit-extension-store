//
//  AddLanguageServerToSDKType.swift
//  
//
//  Created by Pavel Kasila on 16.04.22.
//

import Fluent

struct AddLanguageServerToSDKType: AsyncMigration {
    func prepare(on database: Database) async throws {
        _ = try await database.enum("sdk_type")
            .case("language_server")
            .update()
    }

    func revert(on database: Database) async throws {
        _ = try await database.enum("sdk_type")
            .deleteCase("language_server")
            .update()
    }
}
