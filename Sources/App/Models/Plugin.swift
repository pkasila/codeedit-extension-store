//
//  Plugin.swift
//  
//
//  Created by Pavel Kasila on 30.03.22.
//

import Fluent
import Vapor
import Crypto

final class Plugin: Model, Content {
    static let schema = "plugins"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "manifest")
    var manifest: PluginManifest

    @Enum(key: "release_management")
    var management: ReleaseManagement

    @Enum(key: "sdk")
    var sdk: SDK

    @Children(for: \.$plugin)
    var releases: [PluginRelease]

    @OptionalChild(for: \.$plugin)
    var hookInfo: PluginHookInfo?

    @Field(key: "author")
    var author: UUID

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    @Field(key: "ban")
    var ban: Ban?

    init() { }

    init(id: UUID? = nil, manifest: PluginManifest, releaseManagement: ReleaseManagement, sdk: SDK, author: UUID) {
        self.id = id
        self.manifest = manifest
        self.management = releaseManagement
        self.sdk = sdk
        self.author = author
        self.ban = nil
    }

    func applyCreate(_ src: Create) {
        self.manifest = src.manifest
        self.management = src.management
        self.sdk = src.sdk
    }

    private enum CodingKeys: String, CodingKey {
        case id, manifest, management, sdk, releases, author, createdAt, updatedAt, deletedAt, ban
    }
}

extension Plugin {
    struct PluginManifest: Codable {
        var name: String
        var displayName: String
        var homepage: URL?
        var repository: URL?
        var issues: URL?
    }

    enum ReleaseManagement: String, Codable {
        case githubReleases = "gh_releases"
        case codeedit = "codeedit"
    }

    enum SDK: String, Codable {
        case swift = "swift"
        case js = "js"
        case jsx = "jsx"
    }

    struct Ban: Codable {
        var bannedBy: UUID
        var reason: String
    }

    struct Create: Codable {
        var manifest: PluginManifest
        var management: ReleaseManagement
        var sdk: SDK

        func toPlugin(user: UUID) -> Plugin {
            return .init(id: nil, manifest: manifest, releaseManagement: management, sdk: sdk, author: user)
        }
    }
}
