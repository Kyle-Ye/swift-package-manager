/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

import Foundation
import PackageLoading
import PackageModel
import TSCBasic

public struct MockDependency {
    public typealias Requirement = PackageDependency.SourceControl.Requirement

    public let deprecatedName: String?
    public let location: Location
    public let products: ProductFilter

    init(deprecatedName: String? = nil, location: Location, products: ProductFilter = .everything) {
        self.deprecatedName = deprecatedName
        self.location = location
        self.products = products
    }

    // TODO: refactor this when adding registry support
    public func convert(baseURL: AbsolutePath, identityResolver: IdentityResolver) throws -> PackageDependency {
        switch self.location {
        case .fileSystem(let path):
            let path = baseURL.appending(path)
            let remappedPath = try AbsolutePath(validating: identityResolver.mappedLocation(for: path.pathString))
            let identity = try identityResolver.resolveIdentity(for: remappedPath)
            return .fileSystem(
                identity: identity,
                deprecatedName: self.deprecatedName,
                path: remappedPath,
                productFilter: self.products
            )
        case .localSourceControl(let path, let requirement):
            let absolutePath = baseURL.appending(path)
            let remappedPath = try AbsolutePath(validating: identityResolver.mappedLocation(for: absolutePath.pathString))
            let identity = try identityResolver.resolveIdentity(for: remappedPath)
            return .localSourceControl(
                identity: identity,
                deprecatedName: self.deprecatedName,
                path: remappedPath,
                requirement: requirement,
                productFilter: self.products
            )
        case .remoteSourceControl(let url, let requirement):
            let remappedURLString = identityResolver.mappedLocation(for: url.absoluteString)
            guard let remappedURL = URL(string: remappedURLString) else {
                throw StringError("invalid url: \(remappedURLString))")
            }
            let identity = try identityResolver.resolveIdentity(for: remappedURL)
            return .remoteSourceControl(
                identity: identity,
                deprecatedName: self.deprecatedName,
                url: remappedURL,
                requirement: requirement,
                productFilter: self.products
            )
        }
    }

    public static func fileSystem(path: String, products: ProductFilter = .everything) -> MockDependency {
        MockDependency(location: .fileSystem(path: RelativePath(path)), products: products)
    }

    public static func sourceControl(path: String, requirement: Requirement, products: ProductFilter = .everything) -> MockDependency {
        .sourceControl(path: RelativePath(path), requirement: requirement, products: products)
    }

    public static func sourceControl(path: RelativePath, requirement: Requirement, products: ProductFilter = .everything) -> MockDependency {
        MockDependency(location: .localSourceControl(path: path, requirement: requirement), products: products)
    }

    public static func sourceControlWithDeprecatedName(name: String, path: String, requirement: Requirement, products: ProductFilter = .everything) -> MockDependency {
        MockDependency(deprecatedName: name, location: .localSourceControl(path: RelativePath(path), requirement: requirement), products: products)
    }

    public static func sourceControl(url: String, requirement: Requirement, products: ProductFilter = .everything) -> MockDependency {
        .sourceControl(url: URL(string: url)!, requirement: requirement, products: products)
    }

    public static func sourceControl(url: URL, requirement: Requirement, products: ProductFilter = .everything) -> MockDependency {
        MockDependency(location: .remoteSourceControl(url: url, requirement: requirement), products: products)
    }

    public enum Location {
        case fileSystem(path: RelativePath)
        case localSourceControl(path: RelativePath, requirement: Requirement)
        case remoteSourceControl(url: URL, requirement: Requirement)
    }
}
