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

        
        context("when registering instance") {
            it("should register type under identifier if provided") {
                container.register(identifier: "classA") { A() }
                let value : A = try! container.resolve(identifier:"classA")
                expect(value).notTo(beNil())
            }
            
            it("should successfully register closure with a reference type") {
              
                container.register { A() }
                let value : A = try! container.resolve()
                expect(value).notTo(beNil())
            }
            
            it("should successfully register closure with a value type") {

                container.register { SA() }
                let value : SA = try! container.resolve()
                expect(value).notTo(beNil())
            }


            it ("should return classes for registered types") {

                container.register { A() }

                let value : A = try! container.resolve()
                expect(type(of: value)) === A.self
            }

            it ("should throw error for unregistereed types") {

                container.register { A() }
                expect {
                    let value : B = try container.resolve()
                    expect(value).to(beNil())
                }.to(throwError(IOCContainer.ContainerError.noPriorRegistration))
               
            }
        }
        
        
        
        context("when working with scope") {
            it("should return differenct objects when specifying a unique scope (reference type)") {
                container.register { A() }

                let value1 : A = try! container.resolve()
                let value2 : A = try! container.resolve()
                expect(value1) !== value2
            }

            it("should return differenct objects when specifying a unique scope (value type)") {
                container.register { SA() }

                let value1 : SA = try! container.resolve()
                let value2 : SA = try! container.resolve()
                expect(value1) != value2
            }

            it("should return the same object when specifying a scope of shared (reference type)") {
                container.register { A() }

                let value1 : A = try! container.resolve(scope: .shared)
                let value2 : A = try! container.resolve(scope: .shared)
                expect(value1) === value2
            }

            it("should return the same object when specifying a scope of shared (value type)") {
                container.register { SA() }

                let value1 : SA = try! container.resolve(scope: .shared)
                let value2 : SA = try! container.resolve(scope: .shared)
                expect(value1) == value2
            }
            
            it("should return unique or shared instanced for the same registered type") {
                container.register { SA() }

                let value1 : SA = try! container.resolve(scope: .shared)
                let value2 : SA = try! container.resolve(scope: .shared)
                expect(value1) == value2
                
                let value3 : SA = try! container.resolve(scope:.unique)
                expect(value3) != value1
            }

            it ("should default to unique scope when scope is not provided") {
                container.register { A() }

                let value1 : A = try! container.resolve()
                let value2 : A = try! container.resolve()
                expect(value1) !== value2
            }


            it("should retain a shared object when specifying a scope of shared") {
                var aValue = A()
                container.register { () -> A in
                    return aValue
                }
                let b = B()
                b.a = try! container.resolve(scope: .shared) as A
                expect(b.a) === aValue
                expect(b.a).notTo(beNil())
                aValue = A()
                expect(b.a).notTo(beNil())
            }
        }

        context("when calling deregister") {
            it("should successfully unregister types with identifier") {
                container.register(identifier:"classA") { A() }
                container.deregister(identifier:"classA",type:A.self)
                expect {
                    let value : A = try container.resolve()
                    expect(value).to(beNil())
                }.to(throwError(IOCContainer.ContainerError.noPriorRegistration))
            }
            it("should successfully unregister closures with scope unique") {

                container.register { A() }
                container.deregister(type:A.self)
                expect {
                    let value : A = try container.resolve()
                    expect(value).to(beNil())
                }.to(throwError(IOCContainer.ContainerError.noPriorRegistration))
            }

            it("should successfully unregister closures with scope shared ") {
                var aValue1 : A? = A()
                let aValue2 = A()

                container.register {
                    return aValue1 ?? aValue2
                }
                var a : A = try! container.resolve(scope:.shared)
                weak var weakA : A? = a
                a = A()
                aValue1 = nil
                container.deregister(type:A.self)
                expect(weakA).to(beNil())
            }
        }

        context("when instantiating objects") {
            it("should succesfully instantiate simple objects") {
                container.register { A() }

                let a : A = try! container.resolve()
                expect(a).notTo(beNil())
            }

            it("should successfully instantiate dependent objects e.g A has dependency of B") {
                container.register { B2() }

                container.register() { [weak container] () -> A2 in
                    let b2 : B2 = try! container!.resolve()
                    expect(b2).notTo(beNil())
                    return A2(b2: b2)
                }
                let a2 : A2 = try! container.resolve()
                expect(a2).notTo(beNil())
                expect(a2.b2).notTo(beNil())
            }

            it("should throw error when handling circular dependent objects") {
                var containerError : IOCContainer.ContainerError? = nil
                container.register(identifier:"classA") { [weak container] () -> A3 in
                    var b3 : B3?
                    do {
                        b3 = try container!.resolve(identifier:"classB")
                    }
                    catch let error as IOCContainer.ContainerError {
                        containerError = error
                    }
                    catch {}
                    return A3(b3: b3)
                }
                container.register(identifier:"classB") { [weak container] () -> B3  in
                    var a3 : A3?
                    do {
                        a3 = try container!.resolve(identifier:"classA")
                    }
                    catch {}
                    expect(a3).notTo(beNil())
                    return B3(a3: a3)
                }
                let a3 : A3 = try! container.resolve(identifier:"classA")
                expect(a3).notTo(beNil())
                expect(containerError) == IOCContainer.ContainerError.recursion

            }
        }
    }
            
}


