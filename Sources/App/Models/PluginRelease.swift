//
//  PluginRelease.swift
//  
//
//  Created by Pavel Kasila on 30.03.22.
//

import Fluent
import Vapor

final class PluginRelease: Model, Content {
    static let schema = "plugin_releases"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "plugin_id")
    var plugin: Plugin

    @Field(key: "external_id")
    var externalID: String

    @Field(key: "version")
    var version: String

    @Field(key: "tarball_url")
    var tarball: URL?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    init() { }

    init(id: UUID? = nil, pluginID: Plugin.IDValue) {
        self.id = id
        self.$plugin.id = pluginID
    }
}
