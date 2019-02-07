//
//  ThreadgroupSize.swift
//  mtlswift
//
//  Created by Andrey Volodin on 07/02/2019.
//

public enum ThreadgroupSize {
    case max
    case executionWidth
    case constant(x: Int, y: Int, z: Int)
    case provided
}
