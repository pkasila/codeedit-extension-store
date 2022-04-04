//
//  PluginHookInfo.swift
//  
//
//  Created by Pavel Kasila on 3.04.22.
//

import Fluent
import Vapor
import Crypto

final class PluginHookInfo: Model, Content {
    static let schema = "plugin_hooks"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "plugin_id")
    var plugin: Plugin

    @Field(key: "secret_data")
    var secretData: Data

    init() { }

    init(id: UUID? = nil, secretData: Data, pluginID: Plugin.IDValue) {
        self.id = id
        self.secretData = secretData
        self.$plugin.id = pluginID
    }

    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    static func generateSecret() throws -> (String, Data) {
        guard let appKey = Environment.get("HOOK_APP_MASTER_KEY")?.data(using: .utf8) else {
            throw Abort(.internalServerError)
        }

        let secret = PluginHookInfo.randomString(length: 20)
        guard let secretData = secret.data(using: .utf8) else {
            throw Abort(.internalServerError)
        }
        let box = try AES.GCM.seal(secretData, using: .init(data: appKey), nonce: .init())

        return (secret, box.combined!)
    }
}
