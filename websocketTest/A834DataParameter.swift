//
//  A834DataParameter.swift
//  websocketTest
//
//  Created by Greg Mardon on 2020-07-28.
//

import Foundation

struct A834DataParameter : Codable {
    var parameterName:String
    var value:String
    
    enum CodingKeys: String, CodingKey {
        case parameterName = "k"
        case value = "v"
    }
}
