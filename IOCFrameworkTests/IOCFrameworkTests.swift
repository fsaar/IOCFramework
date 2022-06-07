//
//  IOCFrameworkTests.swift
//  IOCFrameworkTests
//
//  Created by Frank Saar on 07/06/2022.
//


import Quick
import Nimble
import UIKit

@testable import IOCFramework

struct SA : Hashable {
    let uuid = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid.uuidString)
    }
    
    static func ==(lhs : Self,rhs : Self) -> Bool {
        return lhs.uuid.uuidString == rhs.uuid.uuidString
    }
}



class A {
    
}

class B {
    weak var a : A?
}

class B2 {
    
}
class A2 {
    var b2 : B2?
    
    init(b2 : B2?) {
        self.b2 = b2
    }
}

class A3 {
    weak var b3 : B3?
    init(b3: B3? = nil) {
        self.b3 = b3
    }
}

class B3 {
    weak var a3 : A3?
    init(a3 : A3? = nil) {
        self.a3 = a3
    }
}




class IOCContainerSpecs: QuickSpec {
    
    override func spec() {
        var container : IOCContainer!

        beforeEach {
            container = IOCContainer()
        }

        
        context("when calling container instance") {
            it("should successfully register closure with a reference type") {
              
                container.register() { A() }
                let value = try! container.resolve(type:A.self)
                expect(value).notTo(beNil())
            }
            
            it("should successfully register closure with a value type") {
              
                container.register() { SA() }
                let value = try! container.resolve(type:SA.self)
                expect(value).notTo(beNil())
            }
            
            
            it ("should return classes for registered types") {
              
                container.register() {
                    return A()
                }
                let value = try! container.resolve(type:A.self)!
                expect(type(of: value)) === A.self
            }
            
            it ("should return nil for unregistereed types") {
              
                container.register() {
                    return A()
                }
                let value = try! container.resolve(type:B.self)
                expect(value).to(beNil())
            }
        }
        
        
        
        context("when working with scope") {
            it("should return differenct objects when specifying a unique scope (reference type)") {
                container.register(scope:.unique) {
                    return A()
                }
                let value1 = try! container.resolve(type:A.self)
                let value2 = try! container.resolve(type:A.self)
                expect(value1) !== value2
            }
            
            it("should return differenct objects when specifying a unique scope (value type)") {
                container.register(scope:.unique) {
                    return SA()
                }
                let value1 = try! container.resolve(type:SA.self)
                let value2 = try! container.resolve(type:SA.self)
                expect(value1) != value2
            }
            
            it("should return the same object when specifying a scope of shared (reference type)") {
                container.register(scope:.shared) {
                    return A()
                }
                let value1 = try! container.resolve(type:A.self)
                let value2 = try! container.resolve(type:A.self)
                expect(value1) === value2
            }
            
            it("should return the same object when specifying a scope of shared (value type)") {
                container.register(scope:.shared) {
                    return SA()
                }
                let value1 = try! container.resolve(type:SA.self)
                let value2 = try! container.resolve(type:SA.self)
                expect(value1) == value2
            }
            
            it ("should default to unique scope when scope is not provided") {
                container.register() {
                    return A()
                }
                let value1 = try! container.resolve(type:A.self)
                let value2 = try! container.resolve(type:A.self)
                expect(value1) !== value2
            }
            
            
            it("should retain a shared object when specifying a scope of shared") {
                var aValue = A()
                container.register(scope:.shared) { () -> A in
                    return aValue
                }
                let b = B()
                b.a = try! container.resolve(type:A.self)
                expect(b.a) === aValue
                expect(b.a).notTo(beNil())
                aValue = A()
                expect(b.a).notTo(beNil())
            }
        }
        
        context("when calling deregister") {
            it("should successfully unregister closures with scope unique") {
              
                container.register(scope:.unique) {
                    return A()
                }
                container.deregister(type:A.self)
                let value = try! container.resolve(type:A.self)
                expect(value).to(beNil())
            }
          
            it("should successfully unregister closures with scope shared ") {
                var aValue1 : A? = A()
                let aValue2 : A = A()

                container.register(scope:.shared) {
                    return aValue1 ?? aValue2
                }
                weak var weakA = try! container.resolve(type:A.self)
                aValue1 = nil
                container.deregister(type:A.self)
                expect(weakA).to(beNil())
            }
        }
        
        context("when instantiating objects") {
            it("should succesfully instantiate simple objects") {
                container.register() {
                    return A()
                }
                let a = try! container.resolve(type: A.self)
                expect(a).notTo(beNil())
            }
            
            it("should successfully instantiate dependent objects e.g A has dependency of B") {
                container.register() {
                    return B2()
                }
                container.register() { [weak container] () -> A2 in
                    let b2 = try! container?.resolve(type: B2.self)
                    expect(b2).notTo(beNil())
                    return A2(b2: b2)
                }
                let a2 = try! container.resolve(type: A2.self)
                expect(a2).notTo(beNil())
                expect(a2?.b2).notTo(beNil())
            }
            
            it("should handle circular dependent objects gracefully i.e. bail at certain recursion depth") {
                container.register() { [weak container] () -> A3 in
                    let b3 = try? container?.resolve(type: B3.self)
                    return A3(b3: b3)
                }
                container.register() { [weak container] () -> B3  in
                    let a3 = try? container?.resolve(type: A3.self)
                    expect(a3).notTo(beNil())
                    return B3(a3: a3)
                }
                let a3 = try! container.resolve(type: A3.self)
                expect(a3).notTo(beNil())
  
            }
        }
    }
            
}


