//
//  WebhooksController.swift
//  
//
//  Created by Pavel Kasila on 3.04.22.
//

import Fluent
import Vapor
import Crypto

struct WebhooksController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let webhooks = routes.grouped("webhooks")
        webhooks.group(":pluginID") { plugin in
            plugin.post("github", use: hookGitHub)
        }
    }

    func hookGitHub(req: Request) async throws -> PluginRelease {
        guard let hmac = req.headers.first(name: .init("X-Hub-Signature-256"))?
                .replacingOccurrences(of: "sha256=", with: "")
                .replacingOccurrences(of: " ", with: "") else {
            throw Abort(.unauthorized)
        }

        guard let plugin = try await Plugin.find(req.parameters.get("pluginID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await plugin.$hookInfo.load(on: req.db)

        // verify HMAC
        guard let sealedKey = plugin.hookInfo?.secretData else {
            throw Abort(.notFound)
        }

        guard let appKey = Environment.get("HOOK_APP_MASTER_KEY")?.data(using: .utf8) else {
            throw Abort(.internalServerError)
        }

        let box = try AES.GCM.SealedBox(combined: sealedKey)
        let pluginKey = try AES.GCM.open(box, using: .init(data: appKey))

        if let data = req.body.string?.data(using: .utf8) {
            var check = HMAC<SHA256>.init(key: .init(data: pluginKey))
            check.update(data: data)
            if check.finalize().hexEncodedString() != hmac {
                throw Abort(.unauthorized)
            }
        } else {
            throw Abort(.unauthorized)
        }
        // end: verify HMAC

        if plugin.management != .githubReleases {
            throw Abort(.notFound)
        }

        let event = try req.content.decode(GitHubReleaseHook.self)

        if event.action == .deleted {
            let release = try await plugin.$releases.query(on: req.db)
                .filter(\.$externalID, .equal, event.release.tagName).first()
            try await release?.delete(on: req.db)

            throw Abort(.ok)
        }

        let release = try await plugin.$releases.query(on: req.db)
            .filter(\.$externalID, .equal, event.release.tagName).first() ?? PluginRelease(pluginID: try plugin.requireID())

        release.externalID = event.release.tagName
        release.version = event.release.tagName
        release.tarball = event.release.assets.first(where: {$0.name == "extension.tar"})?.browserDownloadURL.absoluteString

        try await release.save(on: req.db)

        return release
    }
}

fileprivate struct GitHubReleaseHook: Codable {
    var action: Action
    var release: Release

    enum Action: String, Codable {
        case published = "published"
        case unpublished = "unpublished"
        case created = "created"
        case edited = "edited"
        case deleted = "deleted"
        case prereleased = "prereleased"
        case released = "released"
    }

    struct Release: Codable {
        var id: Int
        var tagName: String
        var assets: [ReleaseAsset]

        enum CodingKeys: String, CodingKey {
            case id
            case tagName = "tag_name"
            case assets
        }
    }

    struct ReleaseAsset: Codable {
        var id: Int
        var name: String
        var url: URL
        var browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case url
            case browserDownloadURL = "browser_download_url"
        }
    }
}
