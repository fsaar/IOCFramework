//
//  IOCFramework.swift
//  IOCFramework
//
//  Created by Frank Saar on 07/06/2022.
//

import Foundation

public class IOCContainer {
    private let MaxRecursionDepth = 10
    public enum ContainerError : Error {
        case recursion
        case noPriorRegistration
        case consistencyError
        case typeRegistered
    }
    
    public enum Scope  {
        case unique
        case shared
    }
    
    private var resolverRecursionCount = 0
    public typealias ClassResolverBlock = () -> Any
    private var blockStorage : [String:ClassResolverBlock] = [:]
    private var singletonStorage : [String:Any] = [:]

    
    public init() {}
    
    /// Registers Type with IOCContainer. Type will be inferred from closure return type.
    ///
    /// - Parameters:
    ///     - identifier: optional identifier to use for registered type
    ///     - block: closure to instantiate type when requested (see resolve)
    /// - Throws: 'ContainerError.typeRegistered' when type already registered / identifier already used
    public func register<T>(identifier: String? = nil, block: @escaping () -> T ) throws {
        let identifier = key(with:identifier,for: T.self)
        guard case .none =  blockStorage[identifier] else {
            throw ContainerError.typeRegistered
        }
        blockStorage[identifier] = block
    }
    
    /// Resolves registered type

    /// - Parameters:
    ///     - identifier: optional identifier to use for registered type
    ///     - scope: .unique to always return new instance or .shared to return a previously resolved shared instance
    ///
    /// - Returns: instantiated class of requested Type
    /// - Throws: 'ContainerError.recursion' when max recursion depth has been reached
    public func resolve<T>(identifier: String? = nil,scope : Scope = .unique) throws -> T {
        resolverRecursionCount += 1
        defer {
            resolverRecursionCount -= 1
        }
        guard resolverRecursionCount < MaxRecursionDepth else {
            throw ContainerError.recursion
        }
        let identifier = key(with:identifier,for: T.self)
        guard let block = blockStorage[identifier] else {
            throw ContainerError.noPriorRegistration
        }
        
        switch scope {
        case .unique:
            guard let newInstance = block() as? T else {
                throw ContainerError.consistencyError
            }
            return newInstance
        case .shared:
            if let instance = singletonStorage[identifier] as? T {
                return instance
            }
            guard let newInstance = block() as? T else {
                throw ContainerError.consistencyError
            }
            singletonStorage[identifier] = newInstance
            return newInstance
        }
    }
    
    /// Deregisters previously registered type
    ///
    /// - Parameters:
    ///     - identifier: optional identifier to use for registered type
    ///     - type: type of class to deregister
    public func deregister<T>(identifier: String? = nil,type : T.Type)  {
        let identifier = key(with:identifier,for: T.self)
        blockStorage[identifier] = nil
        singletonStorage[identifier] = nil

    }
}

fileprivate extension IOCContainer {
    
    func key<T>(with identifier: String? = nil,for type:T.Type) -> String {
        guard let identifier = identifier,!identifier.isEmpty else {
            return String(describing: T.self)
        }
        return identifier
    }
}
