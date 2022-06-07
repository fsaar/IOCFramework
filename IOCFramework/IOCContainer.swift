//
//  IOCContainer.swift
//  iocApp
//
//  Created by Frank Saar on 07/06/2022.
//

import Foundation

public class IOCContainer {
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

    public func register<T>(type : T.Type, scope : Scope = .unique,block: @escaping ClassResolverBlock ) {
        let identifier = key(for: type)
        blockStorage[identifier] = (block,scope)
    }
    
    public func resolve<T>(type : T.Type) throws -> T? {
        resolverRecursionCount += 1
        defer {
            resolverRecursionCount -= 1
        }
        guard resolverRecursionCount < 10 else {
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
