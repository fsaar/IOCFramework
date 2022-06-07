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
    }
    
    public enum Scope  {
        case unique
        case shared
    }
    
    private var resolverRecursionCount = 0
    public typealias ClassResolverBlock = () -> Any
    private var blockStorage : [String:(block:ClassResolverBlock,scope:Scope)] = [:]
    private var singletonStorage : [String:Any] = [:]

    
    public init() {}
    
    /// Registers Type with IOCContainer
    ///
    /// - Parameters:
    ///     - scope: scope of registration: .unique (default) or .shared
    ///     - block: closure to instantiate type when requested (see resolve)
    public func register<T>(scope : Scope = .unique,block: @escaping () -> T ) {
        let identifier = key(for: T.self)
        blockStorage[identifier] = (block,scope)
    }
    
    /// Resolves registered type
    ///
    /// - Parameters:
    ///     - type: type of class to resolve
    /// - Returns: instantiate class or nil of no class registered
    /// - Throws: 'ContainerError.recursion' when max recursion depth has been reached
    public func resolve<T>(type : T.Type) throws -> T? {
        resolverRecursionCount += 1
        defer {
            resolverRecursionCount -= 1
        }
        guard resolverRecursionCount < MaxRecursionDepth else {
            throw ContainerError.recursion
        }
        let identifier = key(for: type)
        guard let tuple = blockStorage[identifier] else {
            return nil
        }
        
        switch tuple.scope {
        case .unique:
            let newInstance = tuple.block() as? T
            return newInstance
        case .shared:
            if let instance = singletonStorage[identifier] as? T {
                return instance
            }
            guard let newInstance = tuple.block() as? T else {
                return nil
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
