//
//  AtomicInteger.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 05/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

struct AtomicInteger<Type>: BinaryInteger where Type: BinaryInteger {
    
    typealias Magnitude = Type.Magnitude
    typealias IntegerLiteralType = Type.IntegerLiteralType
    typealias Words = Type.Words
    fileprivate var value: Type
    
    private var semaphore = DispatchSemaphore(value: 1)
    fileprivate func _wait() { semaphore.wait() }
    fileprivate func _signal() { semaphore.signal() }
    
    init() { value = Type() }
    
    init(integerLiteral value: AtomicInteger.IntegerLiteralType) {
        self.value = Type(integerLiteral: value)
    }
    
    init<T>(_ source: T) where T : BinaryInteger {
        value = Type(source)
    }
    
    init(_ source: Int) {
        value = Type(source)
    }
    
    init<T>(clamping source: T) where T : BinaryInteger {
        value = Type(clamping: source)
    }
    
    init?<T>(exactly source: T) where T : BinaryInteger {
        guard let value = Type(exactly: source) else { return nil }
        self.value = value
    }
    
    init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        value = Type(truncatingIfNeeded: source)
    }
    
    init?<T>(exactly source: T) where T : BinaryFloatingPoint {
        guard let value = Type(exactly: source) else { return nil }
        self.value = value
    }
    
    init<T>(_ source: T) where T : BinaryFloatingPoint {
        value = Type(source)
    }
}

// Instance Properties

extension AtomicInteger {
    var words: Type.Words {
        _wait(); defer { _signal() }
        return value.words
    }
    var bitWidth: Int {
        _wait(); defer { _signal() }
        return value.bitWidth
    }
    var trailingZeroBitCount: Int {
        _wait(); defer { _signal() }
        return value.trailingZeroBitCount
    }
    var magnitude: Type.Magnitude {
        _wait(); defer { _signal() }
        return value.magnitude
    }
}

// Type Properties

extension AtomicInteger {
    static var isSigned: Bool { return Type.isSigned }
}

// Instance Methods

extension AtomicInteger {
    
    func quotientAndRemainder(dividingBy rhs: AtomicInteger<Type>) -> (quotient: AtomicInteger<Type>, remainder: AtomicInteger<Type>) {
        _wait(); defer { _signal() }
        rhs._wait(); defer { rhs._signal() }
        let result = value.quotientAndRemainder(dividingBy: rhs.value)
        return (AtomicInteger(result.quotient), AtomicInteger(result.remainder))
    }
    
    func signum() -> AtomicInteger<Type> {
        _wait(); defer { _signal() }
        return AtomicInteger(value.signum())
    }
}


extension AtomicInteger {
    
    fileprivate static func atomicAction<Result, Other>(lhs: AtomicInteger<Type>,
                                                        rhs: Other, closure: (Type, Type) -> (Result)) -> Result where Other : BinaryInteger {
        lhs._wait(); defer { lhs._signal() }
        var rhsValue = Type(rhs)
        if let rhs = rhs as? AtomicInteger {
            rhs._wait(); defer { rhs._signal() }
            rhsValue = rhs.value
        }
        let result = closure(lhs.value, rhsValue)
        return result
    }
    
    fileprivate static func atomicActionAndResultSaving<Other>(lhs: inout AtomicInteger<Type>,
                                                               rhs: Other, closure: (Type, Type) -> (Type)) where Other : BinaryInteger {
        lhs._wait(); defer { lhs._signal() }
        var rhsValue = Type(rhs)
        if let rhs = rhs as? AtomicInteger {
            rhs._wait(); defer { rhs._signal() }
            rhsValue = rhs.value
        }
        let result = closure(lhs.value, rhsValue)
        lhs.value = result
    }
}

// Math Operator Functions

extension AtomicInteger {
    
    static func != <Other>(lhs: AtomicInteger, rhs: Other) -> Bool where Other : BinaryInteger {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 != $1 }
    }
    
    static func != (lhs: AtomicInteger, rhs: AtomicInteger) -> Bool {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 != $1 }
    }
    
    static func % (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 % $1 }
        return self.init(value)
    }
    
    static func %= (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 % $1 }
    }
    
    static func & (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 & $1 }
        return self.init(value)
    }
    
    static func &= (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 & $1 }
    }
    
    static func * (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 * $1 }
        return self.init(value)
    }
    
    static func *= (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 * $1 }
    }
    
    static func + (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 + $1 }
        return self.init(value)
    }
    static func += (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 + $1 }
    }
    
    static func - (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 - $1 }
        return self.init(value)
    }
    
    static func -= (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 - $1 }
    }
    
    static func / (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 / $1 }
        return self.init(value)
    }
    
    static func /= (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 / $1 }
    }
}


// Shifting Operator Functions

extension AtomicInteger {
    static func << <RHS>(lhs:  AtomicInteger<Type>, rhs: RHS) -> AtomicInteger where RHS : BinaryInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 << $1 }
        return self.init(value)
    }
    
    static func <<= <RHS>(lhs: inout AtomicInteger, rhs: RHS) where RHS : BinaryInteger {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 << $1 }
    }
    
    static func >> <RHS>(lhs: AtomicInteger, rhs: RHS) -> AtomicInteger where RHS : BinaryInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 >> $1 }
        return self.init(value)
    }
    
    static func >>= <RHS>(lhs: inout AtomicInteger, rhs: RHS) where RHS : BinaryInteger {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 >> $1 }
    }
}

// Comparing Operator Functions

extension AtomicInteger {
    
    static func < <Other>(lhs: AtomicInteger<Type>, rhs: Other) -> Bool where Other : BinaryInteger {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 < $1 }
    }
    
    static func <= (lhs: AtomicInteger, rhs: AtomicInteger) -> Bool {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 <= $1 }
    }
    
    static func == <Other>(lhs: AtomicInteger, rhs: Other) -> Bool where Other : BinaryInteger {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 == $1 }
    }
    
    static func > <Other>(lhs: AtomicInteger, rhs: Other) -> Bool where Other : BinaryInteger {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 > $1 }
    }
    
    static func > (lhs: AtomicInteger, rhs: AtomicInteger) -> Bool {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 > $1 }
    }
    
    static func >= (lhs: AtomicInteger, rhs: AtomicInteger) -> Bool {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 >= $1 }
    }
    
    static func >= <Other>(lhs: AtomicInteger, rhs: Other) -> Bool where Other : BinaryInteger {
        return atomicAction(lhs: lhs, rhs: rhs) { $0 >= $1 }
    }
}

// Binary Math Operator Functions

extension AtomicInteger {
    
    static func ^ (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 ^ $1 }
        return self.init(value)
    }
    
    static func ^= (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 ^ $1 }
    }
    
    static func | (lhs: AtomicInteger, rhs: AtomicInteger) -> AtomicInteger {
        let value = atomicAction(lhs: lhs, rhs: rhs) { $0 | $1 }
        return self.init(value)
    }
    
    static func |= (lhs: inout AtomicInteger, rhs: AtomicInteger) {
        atomicActionAndResultSaving(lhs: &lhs, rhs: rhs) { $0 | $1 }
    }
    
    static prefix func ~ (x: AtomicInteger) -> AtomicInteger {
        x._wait(); defer { x._signal() }
        return self.init(x.value)
    }
}

// Hashable

extension AtomicInteger {
    
    var hashValue: Int {
        _wait(); defer { _signal() }
        return value.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        _wait(); defer { _signal() }
        value.hash(into: &hasher)
    }
}

// Get/Set

extension AtomicInteger {
    
    // Single  actions
    
    func get() -> Type {
        _wait(); defer { _signal() }
        return value
    }
    
    mutating func set(value: Type) {
        _wait(); defer { _signal() }
        self.value = value
    }
    
    // Multi-actions
    
    func get(closure: (Type)->()) {
        _wait(); defer { _signal() }
        closure(value)
    }
    
    mutating func set(closure: (Type)->(Type)) {
        _wait(); defer { _signal() }
        self.value = closure(value)
    }
}
