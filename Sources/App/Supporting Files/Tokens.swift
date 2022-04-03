//
//  Tokens.swift
//  
//
//  Created by Pavel Kasila on 1.04.22.
//

import Vapor
import JWT

struct UserToken: Content, Authenticatable, JWTPayload {

    var exp: ExpirationClaim
    var sub: UUID
    var realm_access: RealmAccess
    var scope: String

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
        if !scope.contains("EXTENSIONS") {
            throw Abort(.forbidden)
        }
    }
}

struct MaintainerToken: Content, Authenticatable, JWTPayload {

    var exp: ExpirationClaim
    var sub: UUID
    var realm_access: RealmAccess
    var scope: String

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
        if !realm_access.roles.contains("maintainer") {
            throw Abort(.forbidden)
        }
        if !scope.contains("EXTENSIONS") {
            throw Abort(.forbidden)
        }
    }
}

struct RealmAccess: Content {
    var roles: [String]
}
