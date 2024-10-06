//
//  Star.swift
//  ExoskyApp
//
//  Created by Chaehyun Park on 10/5/24.
//

import Foundation

struct ConstellationData: Codable {
    let stars: [Star]
    let constellations: [Constellation]
}

struct Star: Codable {
    let source_id: Int
    var x_normalized: Float
    var y_normalized: Float
    var z_normalized: Float
    let distance_pc: Float
    let apparent_magnitude: Float
    let absolute_magnitude: Float
    let normalized_radius: Float
    let temperature_celsius: Float?
    let radius: Float?
    let name: String?
}

struct Constellation: Codable {
    let constellationName: String
    let numberOfStars: Int
    var lines: [ConstellationLine]

    enum CodingKeys: String, CodingKey {
        case constellationName = "Constellation"
        case numberOfStars = "Number_of_Stars"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        constellationName = try container.decode(String.self, forKey: .constellationName)
        numberOfStars = try container.decode(Int.self, forKey: .numberOfStars)
        
        // Initialize an empty array to hold the constellation lines
        var linesArray: [ConstellationLine] = []
        
        // Iterate over the number of stars to decode the lines dynamically
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        for i in 1...numberOfStars {
            // Create keys dynamically for each line
            let startXKey = DynamicCodingKeys(stringValue: "line\(i)_start_x")
            let startYKey = DynamicCodingKeys(stringValue: "line\(i)_start_y")
            let startZKey = DynamicCodingKeys(stringValue: "line\(i)_start_z")
            let endXKey = DynamicCodingKeys(stringValue: "line\(i)_end_x")
            let endYKey = DynamicCodingKeys(stringValue: "line\(i)_end_y")
            let endZKey = DynamicCodingKeys(stringValue: "line\(i)_end_z")
            
            // Decode if the values exist
            if let startX = try dynamicContainer.decodeIfPresent(Float.self, forKey: startXKey!),
               let startY = try dynamicContainer.decodeIfPresent(Float.self, forKey: startYKey!),
               let startZ = try dynamicContainer.decodeIfPresent(Float.self, forKey: startZKey!),
               let endX = try dynamicContainer.decodeIfPresent(Float.self, forKey: endXKey!),
               let endY = try dynamicContainer.decodeIfPresent(Float.self, forKey: endYKey!),
               let endZ = try dynamicContainer.decodeIfPresent(Float.self, forKey: endZKey!) {
                
                // Add decoded line data to linesArray
                linesArray.append(ConstellationLine(startX: startX, startY: startY, startZ: startZ, endX: endX, endY: endY, endZ: endZ))
            }
        }
        
        lines = linesArray
    }
}

// A struct to decode the dynamic keys for the lines
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

struct ConstellationLine: Codable {
    let startX: Float
    let startY: Float
    let startZ: Float
    let endX: Float
    let endY: Float
    let endZ: Float
}
