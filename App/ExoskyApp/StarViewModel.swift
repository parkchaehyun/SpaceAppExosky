//
//  StarViewModel.swift
//  ExoskyApp
//
//  Created by Chaehyun Park on 10/5/24.
//

// StarViewModel.swift
import Foundation

class StarViewModel {
    var stars: [Star] = []
    var constellations: [Constellation] = []
    
    // Helper function to convert coordinates to SceneKit's system
    func convertToSceneKitCoordinates(x: Float, y: Float, z: Float) -> (Float, Float, Float) {
        let sceneKitX = x
        let sceneKitY = z // z in your data becomes y in SceneKit
        let sceneKitZ = -y // y in your data becomes z in SceneKit, but inverted
        return (sceneKitX, sceneKitY, sceneKitZ)
    }
    
    // Fetch stars from the API
    func fetchStars(from fileName: String, completion: @escaping (Result<[Star], Error>) -> Void) {
        // Load the specified JSON file from the project bundle
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Could not find JSON file \(fileName)"
            ])))
            return
        }
        
        do {
            // Load the data from the file
            let data = try Data(contentsOf: fileUrl)
            let decoder = JSONDecoder()
            
            // Parse the JSON into an array of Star objects
            var starsArray = try decoder.decode([Star].self, from: data)
            
            // Convert each star's coordinates to SceneKit's coordinate system
            starsArray = starsArray.map { star in
                let (newX, newY, newZ) = self.convertToSceneKitCoordinates(x: star.x_normalized, y: star.y_normalized, z: star.z_normalized)
                var updatedStar = star
                updatedStar.x_normalized = newX
                updatedStar.y_normalized = newY
                updatedStar.z_normalized = newZ
                return updatedStar
            }
            
            self.stars = starsArray
            completion(.success(self.stars))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    
    
    // Load constellations based on the selected planet's prefix
    func fetchConstellations(forPlanet planetPrefix: String, completion: @escaping (Result<[Constellation], Error>) -> Void) {
        guard let fileUrl = Bundle.main.url(forResource: "\(planetPrefix)_constellation", withExtension: "json") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Could not find JSON file for planet \(planetPrefix)"
            ])))
            return
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let decoder = JSONDecoder()
            
            var constellationsArray = try decoder.decode([Constellation].self, from: data)
            
            // Convert the coordinates of each constellation's lines
            constellationsArray = constellationsArray.map { constellation in
                var updatedConstellation = constellation
                updatedConstellation.lines = constellation.lines.map { line in
                    let (startX, startY, startZ) = self.convertToSceneKitCoordinates(x: line.startX, y: line.startY, z: line.startZ)
                    let (endX, endY, endZ) = self.convertToSceneKitCoordinates(x: line.endX, y: line.endY, z: line.endZ)
                    return ConstellationLine(startX: startX, startY: startY, startZ: startZ, endX: endX, endY: endY, endZ: endZ)
                }
                return updatedConstellation
            }
            
            self.constellations = constellationsArray
            completion(.success(self.constellations))
        } catch {
            completion(.failure(error))
        }
    }
}
