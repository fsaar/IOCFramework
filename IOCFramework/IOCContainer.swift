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
    ///     - block: closure to instantiate type when requested (see resolve)
    public func register<T>(block: @escaping () -> T ) {
        let identifier = key(for: T.self)
        blockStorage[identifier] = block
    }
    
    /// Resolves registered type

    /// - Parameters:
    ///     - scope: .unique to always return new instance or .shared to return a previously resolved shared instance
    ///
    /// - Returns: instantiate class or nil of no class registered
    /// - Throws: 'ContainerError.recursion' when max recursion depth has been reached
    public func resolve<T>(scope : Scope = .unique) throws -> T {
        resolverRecursionCount += 1
        defer {
            resolverRecursionCount -= 1
        }
        guard resolverRecursionCount < MaxRecursionDepth else {
            throw ContainerError.recursion
        }
        let identifier = key(for: T.self)
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
    ///     - type: type of class to deregister
    public func deregister<T>(type : T.Type)  {
        let identifier = String(describing: T.self)
        blockStorage[identifier] = nil
        singletonStorage[identifier] = nil

    }
}

fileprivate extension IOCContainer {
    
    func key<T>(for type:T.Type) -> String {
        return String(describing: T.self)
    }
}
