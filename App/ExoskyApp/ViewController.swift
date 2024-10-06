//
//  ViewController.swift
//  ExoskyApp
//
//  Created by Chaehyun Park on 10/5/24.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    
    var sceneView: SCNView!
    var cameraNode: SCNNode!
    var bannerView: UIView!
    var starViewModel = StarViewModel()
    var starNameLabel: UILabel!
    var starDistanceLabel: UILabel!
    var starMagnitudeLabel: UILabel!
    var starTemperatureLabel: UILabel!
    var displayedConstellationNames = Set<String>()
    var magnitude4Stars: [SCNNode] = []
    var magnitude6Stars: [SCNNode] = []
    var magnitude8Stars: [SCNNode] = []
    
    
    var isTapGesture = true
    var drawingModeEnabled = false
    var selectedStars: [SCNNode] = []  // Store the selected stars for constellation drawing
    var plusButton: UIButton!          // Declare the doneButton at the class level
    var plusButtonWidthConstraint: NSLayoutConstraint! // Reference to the width constraint
    var cancelButton: UIButton!          // Declare the doneButton at the class level
    var constellationToggleButton: UIButton!  // Declare the toggle switch as a class-level variable
    var customModeButton: UIButton!
    var magnitudeSlider: UISlider!
    var currentSessionLines: [SCNNode] = [] // To track lines drawn in the current session


    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func initialize() {
        // Initialize the SCNView
        sceneView = SCNView()
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(sceneView)

        // Setup Auto Layout constraints for full-screen scene view
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            sceneView.topAnchor.constraint(equalTo: self.view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // Create the scene
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = false

//        loadAllStars()

        // Add camera, gesture recognizers, and setup skybox
        setupCamera(scene: scene)
        addGestureRecognizers()
        setupBanner()
        setupSkybox()
        
        setupConstellationToggleButton()
        setupCustomModeButton()
        
        // Add the "+" button and Done button
        setupButtons()
        setupMagnitudeSlider()
    }
    
    func loadAllStars(forPlanet planetPrefix: String, completion: @escaping (Bool) -> Void) {
        initialize()
        
        let dispatchGroup = DispatchGroup()

        // Load stars for magnitude 4
        dispatchGroup.enter()
        loadStarsFromFile(named: "\(planetPrefix)_mag4", planetPrefix: planetPrefix) { [weak self] stars in
            self?.magnitude4Stars = stars
            self?.setStarsVisibility(for: stars, isVisible: false)  // Hidden initially
            dispatchGroup.leave()
        }

        // Load stars for magnitude 6
        dispatchGroup.enter()
        loadStarsFromFile(named: "\(planetPrefix)_mag6", planetPrefix: planetPrefix) { [weak self] stars in
            self?.magnitude6Stars = stars
            self?.setStarsVisibility(for: stars, isVisible: false)  // Hidden initially
            dispatchGroup.leave()
        }

        // Load stars for magnitude 8
        dispatchGroup.enter()
        loadStarsFromFile(named: "\(planetPrefix)_mag8", planetPrefix: planetPrefix) { [weak self] stars in
            self?.magnitude8Stars = stars
            self?.setStarsVisibility(for: stars, isVisible: false)  // Hidden initially
            dispatchGroup.leave()
        }

        // Once all star sets are loaded, show magnitude 6 by default
        dispatchGroup.notify(queue: .main) { [weak self] in
            print("All star sets loaded.")
            // Set magnitude 6 stars to visible by default
            self?.setStarsVisibility(for: self?.magnitude6Stars ?? [], isVisible: true)
            completion(true)
        }
    }


    
    func loadStarsFromFile(named fileName: String, planetPrefix: String, completion: @escaping ([SCNNode]) -> Void) {
        // Extract the magnitude from the last character of the file name
        guard let lastCharacter = fileName.last, let magnitude = Int(String(lastCharacter)) else {
            print("Error: Unable to determine magnitude from file name.")
            return
        }

        starViewModel.fetchStars(from: fileName) { [weak self] starResult in
            DispatchQueue.main.async {
                switch starResult {
                case .success(let stars):
                    print("Successfully fetched stars from \(fileName).json")
                    
                    // Fetch constellations using only the planet prefix, not the magnitude suffix
                    self?.starViewModel.fetchConstellations(forPlanet: planetPrefix) { constellationResult in
                        DispatchQueue.main.async {
                            switch constellationResult {
                            case .success(let constellations):
                                print("Successfully fetched constellations for \(planetPrefix).")
                                let newStars = self?.addStarsAndConstellationsToScene(stars: stars, constellationData: constellations) ?? []
                                completion(newStars)  // Pass the loaded stars back via completion
                            case .failure(let error):
                                print("Error fetching constellations: \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    print("Error fetching stars: \(error)")
                }
            }
        }
    }


    func setupCustomModeButton() {
        customModeButton = UIButton(type: .system)
        customModeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Set the default icon (pencil icon) for the button with a larger size
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular) // Adjust the pointSize as needed
        let pencilImage = UIImage(systemName: "pencil", withConfiguration: config)
        customModeButton.setImage(pencilImage, for: .normal)
        
        // Add the button to the view
        self.view.addSubview(customModeButton)
        
        // Position the button in the top-right corner
        NSLayoutConstraint.activate([
            customModeButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            customModeButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 15),
            customModeButton.widthAnchor.constraint(equalToConstant: 50),  // Adjust width to fit the new size
            customModeButton.heightAnchor.constraint(equalToConstant: 50)  // Adjust height to fit the new size
        ])
        
        // Add a tap action to toggle custom mode
        customModeButton.addTarget(self, action: #selector(toggleCustomMode(_:)), for: .touchUpInside)
    }

    @objc func toggleCustomMode(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        if sender.isSelected {
            // Enter custom sky mode
            enterCustomSkyMode()
        } else {
            
            // Exit custom sky mode
            exitCustomSkyMode()
        }
    }

    func enterCustomSkyMode() {
        // Hide the banner when entering custom mode
        hideBanner()
        removePreviousConstellationNames()
        
        // Hide all default constellations, but leave the stars visible
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            if let type = node.value(forKey: "type") as? String {
                if type == "defaultConstellationLine" || type == "constellationText" {
                    node.isHidden = true // Hide default constellation lines
                }
            }
        }
        
        // Show only custom constellation lines (if any exist)
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            if let type = node.value(forKey: "type") as? String {
                if type == "customConstellationLine" {
                    node.isHidden = false // Show custom constellation lines
                }
            }
        }
        
        // Hide the constellation toggle switch
        constellationToggleButton.isHidden = true
            
        // Show the "+" button for constellation creation
        plusButton.isHidden = false
    }

    func exitCustomSkyMode() {
        // Hide the banner when exiting custom mode
        hideBanner()
        removePreviousConstellationNames()

        // Restore default constellation visibility based on the toggle switch's state
        let shouldShowConstellations = constellationToggleButton.isSelected
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            if let type = node.value(forKey: "type") as? String {
                if type == "defaultConstellationLine" || type == "constellationText" {
                    node.isHidden = !shouldShowConstellations // Show or hide default constellation lines
                }
            }
        }
        
        // Hide all custom constellation lines when exiting custom mode
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            if let type = node.value(forKey: "type") as? String {
                if type == "customConstellationLine" {
                    node.isHidden = true // Hide custom constellation lines
                }
            }
        }
        
        // Show the constellation toggle switch again
        constellationToggleButton.isHidden = false
        
        // Disable custom constellation creation
        drawingModeEnabled = false
        selectedStars.removeAll()
        
        // Hide the "+" button
        plusButton.isHidden = true
        cancelButton.isHidden = true
    }
    
    func setupConstellationToggleButton() {
        // Initialize the button
        let constellationToggleButton = UIButton(type: .system)
        constellationToggleButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Set the constellation image for both states
        constellationToggleButton.setImage(UIImage(named: "Constellation"), for: .normal)
        
        constellationToggleButton.isSelected = false
        
        // Add target to handle tap action
        constellationToggleButton.addTarget(self, action: #selector(toggleConstellationVisibility(_:)), for: .touchUpInside)
        
        // Add the button to the view
        self.view.addSubview(constellationToggleButton)
        
        // Position the button where the switch was
        NSLayoutConstraint.activate([
            constellationToggleButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            constellationToggleButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            constellationToggleButton.widthAnchor.constraint(equalToConstant: 40),  // Adjust size to match the image
            constellationToggleButton.heightAnchor.constraint(equalToConstant: 40)  // Adjust size to match the image
        ])
        
        // Keep a reference to the button so we can update its state later
        self.constellationToggleButton = constellationToggleButton
    }

    @objc func toggleConstellationVisibility(_ sender: UIButton) {
        // Toggle the button's selected state
        sender.isSelected.toggle()
                
        sceneView.scene?.rootNode.enumerateChildNodes { (node, _) in
            if let type = node.value(forKey: "type") as? String,
               type == "defaultConstellationLine" || type == "constellationText" {
                node.isHidden = !sender.isSelected
            }
        }

    }

    // Function to overlay a cross icon on the image
    func overlayCrossOnImage(image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        let imageWithCross = renderer.image { context in
            // Draw the original image
            image.draw(at: CGPoint.zero)
            
            // Draw the cross icon
            if let crossImage = UIImage(named: "cross_icon") {  // Replace "cross_icon" with your cross icon image name
                let crossRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                crossImage.draw(in: crossRect, blendMode: .normal, alpha: 1.0)
            }
        }
        
        return imageWithCross
    }
    
    // Add the "+" button to the bottom-right corner of the screen
    func setupButtons() {
        // "+" button setup (already exists)
        let plusButton = UIButton(type: .system)
        plusButton.setTitle("+", for: .normal)
        plusButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        plusButton.setTitleColor(.white, for: .normal)
        plusButton.layer.cornerRadius = 25
        plusButton.clipsToBounds = true
        plusButton.addTarget(self, action: #selector(enterDrawingMode), for: .touchUpInside)
        self.view.addSubview(plusButton)
        
        // Set initial state of "+" button to hidden since we are not in custom mode yet
        plusButton.isHidden = true
        
        plusButtonWidthConstraint = plusButton.widthAnchor.constraint(equalToConstant: 50)
        // Place the button at the bottom-right
        NSLayoutConstraint.activate([
            plusButtonWidthConstraint,
            plusButton.heightAnchor.constraint(equalToConstant: 50),
            plusButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            plusButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Cancel button setup
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.backgroundColor = UIColor(rgbRed: 255, green: 102, blue: 102, alpha: 0.7) // Slightly lighter red
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 25
        cancelButton.clipsToBounds = true
        cancelButton.isHidden = true // Initially hidden
        cancelButton.addTarget(self, action: #selector(cancelDrawingMode), for: .touchUpInside)
        self.view.addSubview(cancelButton)
        
        // Place the cancel button on the bottom-left
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            cancelButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Keep a reference to the buttons to show/hide later
        self.plusButton = plusButton
        self.cancelButton = cancelButton
        self.view.addSubview(cancelButton)
    }
    
    func setupMagnitudeSlider() {
        magnitudeSlider = UISlider()
        magnitudeSlider.translatesAutoresizingMaskIntoConstraints = false
        magnitudeSlider.minimumValue = 0 // Represents magnitude 4
        magnitudeSlider.maximumValue = 2 // Represents magnitude 8
        magnitudeSlider.value = 1 // Default value (magnitude 6)
        magnitudeSlider.isContinuous = false // Snap to values
        magnitudeSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2)) // Rotate to vertical

        magnitudeSlider.addTarget(self, action: #selector(magnitudeSliderChanged(_:)), for: .valueChanged)

        self.view.addSubview(magnitudeSlider)

        // Constraints to align the slider with the customModeButton on the right middle
        NSLayoutConstraint.activate([
            magnitudeSlider.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 5),
            magnitudeSlider.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            magnitudeSlider.widthAnchor.constraint(equalToConstant: 200), // Adjust for length of slider
        ])
    }

    @objc func magnitudeSliderChanged(_ sender: UISlider) {
        let magnitudeLevel = round(sender.value) // Round to nearest whole value
        sender.setValue(magnitudeLevel, animated: false) // Snap to the nearest value (0, 1, or 2)

        // Hide all stars before showing the selected set
        setStarsVisibility(for: magnitude4Stars, isVisible: false)
        setStarsVisibility(for: magnitude6Stars, isVisible: false)
        setStarsVisibility(for: magnitude8Stars, isVisible: false)

        // Show stars based on the selected magnitude
        switch magnitudeLevel {
        case 0:
            setStarsVisibility(for: magnitude4Stars, isVisible: true)
        case 1:
            setStarsVisibility(for: magnitude6Stars, isVisible: true)  // Default
        case 2:
            setStarsVisibility(for: magnitude8Stars, isVisible: true)
        default:
            break
        }
    }

    func setStarsVisibility(for stars: [SCNNode], isVisible: Bool) {
        stars.forEach { $0.isHidden = !isVisible }
    }

    func removeStars(from stars: inout [SCNNode]) {
        stars.forEach { $0.removeFromParentNode() }
        stars.removeAll()
    }

    @objc func cancelDrawingMode() {
        // Hide the cancel button
        for subview in self.view.subviews {
            if let cancelButton = subview as? UIButton, cancelButton.title(for: .normal) == "Cancel" {
                cancelButton.isHidden = true
            }
        }

        // Reset the drawing mode
        drawingModeEnabled = false
        selectedStars.removeAll()

        // Remove the constellation lines created during this session
        for lineNode in currentSessionLines {
            lineNode.removeFromParentNode()
        }

        // Clear the session lines array after canceling
        currentSessionLines.removeAll()

        // Reset the "+" button to its initial state
        UIView.animate(withDuration: 0.2, animations: {
            self.plusButton.setTitle("+", for: .normal)
            self.plusButtonWidthConstraint.constant = 50
            self.plusButton.contentHorizontalAlignment = .center
            self.view.layoutIfNeeded()
        }) { _ in
            self.plusButton.removeTarget(self, action: #selector(self.finishConstellation), for: .touchUpInside)
            self.plusButton.addTarget(self, action: #selector(self.enterDrawingMode), for: .touchUpInside)
        }
    }



    @objc func enterDrawingMode() {
        drawingModeEnabled = true
        selectedStars.removeAll() // Clear previously selected stars
        
        // Clear the current session lines array
        currentSessionLines.removeAll()
        
        hideBanner()

        // Check the toggle switch and turn it off if it's on to hide constellations
        if constellationToggleButton.isSelected {
            toggleConstellationVisibility(constellationToggleButton)
        }

        // Show the cancel button when entering drawing mode
        for subview in self.view.subviews {
            if let cancelButton = subview as? UIButton, cancelButton.title(for: .normal) == "Cancel" {
                cancelButton.isHidden = false
            }
        }

        // Stretch the "+" button to the left and then change the title to "Done"
        UIView.animate(withDuration: 0.2, animations: {
            self.plusButtonWidthConstraint.constant = 100
            self.plusButton.contentHorizontalAlignment = .center
            self.view.layoutIfNeeded()
        }) { _ in
            self.plusButton.setTitle("Done", for: .normal)
            self.plusButton.removeTarget(self, action: #selector(self.enterDrawingMode), for: .touchUpInside)
            self.plusButton.addTarget(self, action: #selector(self.finishConstellation), for: .touchUpInside)
        }
    }


    @objc func finishConstellation() {
        // Check if there are any lines drawn before asking for the constellation name
        if currentSessionLines.isEmpty {
            // No lines were drawn, so just exit drawing mode
            print("No lines drawn, exiting drawing mode.")

            drawingModeEnabled = false
            selectedStars.removeAll()

            // Reset the "+" button to its initial state
            UIView.animate(withDuration: 0.2, animations: {
                self.plusButton.setTitle("+", for: .normal)
                self.plusButtonWidthConstraint.constant = 50
                self.plusButton.contentHorizontalAlignment = .center
                self.cancelButton.isHidden = true
                self.view.layoutIfNeeded()
            }) { _ in
                self.plusButton.removeTarget(self, action: #selector(self.finishConstellation), for: .touchUpInside)
                self.plusButton.addTarget(self, action: #selector(self.enterDrawingMode), for: .touchUpInside)
            }

            return  // Exit the function early since there are no lines to name
        }

        // If lines are drawn, ask for the constellation name
        let alertController = UIAlertController(title: nil, message: "Name your constellation!", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Enter"
        }

        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if let constellationName = alertController.textFields?.first?.text, !constellationName.isEmpty {
                print("Constellation named: \(constellationName)")
                self?.finalizeCustomConstellation(with: constellationName)
                self?.drawingModeEnabled = false
                self?.selectedStars.removeAll()

                // Reset the "+" button to its initial state
                UIView.animate(withDuration: 0.2, animations: {
                    self?.plusButton.setTitle("+", for: .normal)
                    self?.plusButtonWidthConstraint.constant = 50
                    self?.plusButton.contentHorizontalAlignment = .center
                    self?.view.layoutIfNeeded()
                    self?.cancelButton.isHidden = true
                }) { _ in
                    self?.plusButton.removeTarget(self, action: #selector(self?.finishConstellation), for: .touchUpInside)
                    self?.plusButton.addTarget(self, action: #selector(self?.enterDrawingMode), for: .touchUpInside)
                }

                // Clear the current session lines array
                self?.currentSessionLines.removeAll()
            } else {
                print("No name provided for the constellation.")
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            print("Constellation creation cancelled.")
            self?.drawingModeEnabled = false
            self?.selectedStars.removeAll()
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }



    func finalizeCustomConstellation(with name: String) {
        // Logic to finalize the constellation with the provided name
        print("Finalizing constellation: \(name)")
        // Apply the constellation name to all custom lines or any further processing needed.
        
        // For example, iterate through custom constellation lines and set the name
        sceneView.scene?.rootNode.enumerateChildNodes { node, _ in
            if let type = node.value(forKey: "type") as? String, type == "customConstellationLine" {
                node.name = name
            }
        }
    }

    
    func printConstellations(_ constellations: [Constellation]) {
        for constellation in constellations {
            print("Constellation: \(constellation.constellationName), Number of Stars: \(constellation.numberOfStars)")
            
            for (index, line) in constellation.lines.enumerated() {
                print("Line \(index + 1): Start (\(line.startX), \(line.startY), \(line.startZ)) -> End (\(line.endX), \(line.endY), \(line.endZ))")
            }
        }
    }

    
//    func setupSkybox() {
//        // Load skybox images
//        let skyboxImages = [
//            UIImage(named: "Right")!,
//            UIImage(named: "Left")!,
//            UIImage(named: "Up")!,
//            UIImage(named: "Down")!,
//            UIImage(named: "Front")!,
//            UIImage(named: "Back")!
//        ]
//        
//        // Set the skybox as the scene's background
//        sceneView.scene?.background.contents = skyboxImages
//
//    }
    
    func setupSkybox() {
        let skySphere = SCNSphere(radius: 500.0) // Adjust radius as needed
        skySphere.segmentCount = 64

        if let skyImage = UIImage(named: "Texture") {
            let skyMaterial = SCNMaterial()
            skyMaterial.diffuse.contents = skyImage
            skyMaterial.isDoubleSided = true
            skyMaterial.cullMode = .front
            skyMaterial.lightingModel = .constant
            skySphere.materials = [skyMaterial]
        }

        let skyNode = SCNNode(geometry: skySphere)
        skyNode.position = SCNVector3(0, 0, 0)  // Position at the origin

        // Assign a unique name to the skybox
        skyNode.name = "skybox"

        sceneView.scene?.rootNode.addChildNode(skyNode)
    }

    
    func setupBanner() {
        bannerView = UIView()
        bannerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        bannerView.layer.cornerRadius = 10
        bannerView.clipsToBounds = true
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        starNameLabel = UILabel()
        starNameLabel.textColor = .white
        starNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        starNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        starDistanceLabel = UILabel()
        starDistanceLabel.textColor = .white
        starDistanceLabel.font = UIFont.systemFont(ofSize: 14)
        starDistanceLabel.translatesAutoresizingMaskIntoConstraints = false

        // Initialize the new label for apparent magnitude
        starMagnitudeLabel = UILabel()
        starMagnitudeLabel.textColor = .white
        starMagnitudeLabel.font = UIFont.systemFont(ofSize: 14)
        starMagnitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        starTemperatureLabel = UILabel()
        starTemperatureLabel.textColor = .white
        starTemperatureLabel.font = UIFont.systemFont(ofSize: 14)
        starTemperatureLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add labels to the banner view
        bannerView.addSubview(starNameLabel)
        bannerView.addSubview(starDistanceLabel)
        bannerView.addSubview(starMagnitudeLabel)
        bannerView.addSubview(starTemperatureLabel)
        
        // Add the banner to the view
        self.view.addSubview(bannerView)
        
        // Constraints for the banner
        NSLayoutConstraint.activate([
            // Reduce the width (30% of the screen width) to make it narrower
            bannerView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.25),
            bannerView.heightAnchor.constraint(lessThanOrEqualToConstant: 150), // Limit height to make it compact
            bannerView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 10), // Safe area aligned to the left
            bannerView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10), // Safe area aligned to the bottom

            // Star name at the top of the banner
            starNameLabel.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 10),
            starNameLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 10),
            starNameLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -10),
            
            // Star distance label below the name
            starDistanceLabel.topAnchor.constraint(equalTo: starNameLabel.bottomAnchor, constant: 5),
            starDistanceLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 10),
            starDistanceLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -10),

            // Star magnitude label below the distance
            starMagnitudeLabel.topAnchor.constraint(equalTo: starDistanceLabel.bottomAnchor, constant: 5),
            starMagnitudeLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 10),
            starMagnitudeLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -10),

            // Star temperature label below the magnitude
            starTemperatureLabel.topAnchor.constraint(equalTo: starMagnitudeLabel.bottomAnchor, constant: 5),
            starTemperatureLabel.leadingAnchor.constraint(equalTo: bannerView.leadingAnchor, constant: 10),
            starTemperatureLabel.trailingAnchor.constraint(equalTo: bannerView.trailingAnchor, constant: -10),
            starTemperatureLabel.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: -10)
        ])
        
        // Initially hide the banner
        bannerView.alpha = 0.0
    }



    // Show the banner with star information
    func showBanner(for star: SCNNode) {
        print(star.name)
        print(star.worldPosition)
        UIView.animate(withDuration: 0.2, animations: {
            self.bannerView.alpha = 0.0
        }, completion: { _ in
            // Retrieve star information and update the banner
            let starDistance = star.value(forKey: "distance") as? Float
            let starMagnitude = star.value(forKey: "apparent_magnitude") as? Float
            let starTemperature = star.value(forKey: "temperature_celsius") as? Float
            
            // Check if the star has a name, if not set the name label to an empty string
            if let starName = star.name {
                self.starNameLabel.text = starName
            } else {
                self.starNameLabel.text = "" // Set to empty if name is nil
            }
            
            // Update distance (convert parsecs to light years)
            if let distance = starDistance {
                let lightYears = distance * 3.26156
                self.starDistanceLabel.text = String(format: "Distance: %.1f light years", lightYears)
            } else {
                self.starDistanceLabel.text = "Distance: Unknown"
            }
            
            // Update magnitude (limit to 2 decimal places)
            if let magnitude = starMagnitude {
                self.starMagnitudeLabel.text = String(format: "Magnitude: %.2f", magnitude)
            } else {
                self.starMagnitudeLabel.text = "Magnitude: Unknown"
            }

            // Update temperature (limit to 2 decimal places)
            if let temperature = starTemperature {
                self.starTemperatureLabel.text = String(format: "Temperature: %.2f°C", temperature)
            } else {
                self.starTemperatureLabel.text = "Temperature: Unknown"
            }

            self.bannerView.layoutIfNeeded()

            // Fade in the new content
            UIView.animate(withDuration: 0.2) {
                self.bannerView.alpha = 1.0
            }
        })
    }

    

    // Hide the banner
    func hideBanner() {
        UIView.animate(withDuration: 0.3) {
            self.bannerView.alpha = 0.0
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTapGesture = true // Assume it's a tap initially
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        isTapGesture = false // Set to false if touch is moved
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if isTapGesture, let touch = touches.first {
            let location = touch.location(in: sceneView)
            
            // Perform a hit test to find the touched star
            let hitResults = sceneView.hitTest(location, options: nil)

            if let result = hitResults.first {
                let node = result.node
                
                // Check if the node is the skybox and exclude it
                if node.name == "skybox" {
                    print("Skybox was selected, ignoring...")
                    hideBanner()
                    return
                }
                
                // Handle star selection if it's not the skybox
                if drawingModeEnabled, let geometry = node.geometry, geometry is SCNSphere {
                    // Ensure the same star is not selected consecutively
                    if selectedStars.last != node && (selectedStars.count < 2 || selectedStars[selectedStars.count - 2] != node) {
                        print(node.worldPosition)
                        selectedStars.append(node)
                        print("Star \(node.name ?? "unknown") selected for constellation.")
                        
                        // If at least two stars are selected, draw a line between the last two
                        if selectedStars.count >= 2 {
                            let previousStar = selectedStars[selectedStars.count - 2]
                            let currentStar = selectedStars[selectedStars.count - 1]
                            drawLineBetweenStars(node1: previousStar, node2: currentStar, constellationName: "Custom Constellation")
                        }
                    } else {
                        print("Cannot select the same star consecutively.")
                    }
                } else {
                    handleStarSelection(node: node)
                }
            } else {
                hideBanner()
            }
        }
    }



    func handleStarSelection(node: SCNNode) {
        // Check if the node has the custom or default type for constellation lines
        if let type = node.value(forKey: "type") as? String {
            if type == "defaultConstellationLine" {
                // This is a default constellation line, display or hide the constellation name
                if let constellationName = node.name {
                    if displayedConstellationNames.contains(constellationName) {
                        // If the constellation name is already displayed, hide it
                        print("remove")
                        removePreviousConstellationNames()
                    } else {
                        // Otherwise, display the constellation name
                        displayConstellationName(constellationName: constellationName, near: node)
                    }
                }
            } else if type == "customConstellationLine" && !drawingModeEnabled {
                // Show custom constellation name only if we're not in drawing mode
                if let constellationName = node.name {
                    if displayedConstellationNames.contains(constellationName) {
                        removePreviousConstellationNames()
                    } else {
                        displayConstellationName(constellationName: constellationName, near: node)
                    }
                }
            }
        } else if let geometry = node.geometry, geometry is SCNSphere {
            // This is a star, show the banner
            showBanner(for: node)
        }
    }

    func displayConstellationName(constellationName: String, near node: SCNNode) {
        // Check if the constellation name is already displayed
        if displayedConstellationNames.contains(constellationName) {
            print("same")
            return // Do nothing if the name is already displayed
        }

        removePreviousConstellationNames() // Ensure only one constellation name is displayed

        // Retrieve the midpoint from the line node
        if let midpointValue = node.value(forKey: "midpoint") as? NSValue {
            let midpoint = midpointValue.scnVector3Value

            let text = SCNText(string: constellationName, extrusionDepth: 1.0)
            text.font = UIFont.systemFont(ofSize: 10) // Use a more manageable size like 10
            text.firstMaterial?.diffuse.contents = UIColor.cyan

            let textNode = SCNNode(geometry: text)
            textNode.scale = SCNVector3(0.5, 0.5, 0.5) // Scale down the text
            
            // Position the text node near the constellation line node's midpoint
            let positionOffset = SCNVector3(x: 0.003, y: 0.003, z: 0) // Adjust as needed
            textNode.position = SCNVector3(
                midpoint.x + positionOffset.x,
                midpoint.y + positionOffset.y,
                midpoint.z + positionOffset.z
            )
            
            // Make the text face the camera using SCNBillboardConstraint
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = .all
            textNode.constraints = [billboardConstraint]

            // Mark this text node as a constellation name for toggling visibility
            textNode.setValue("constellationText", forKey: "type")
            
            // Add the text node to the scene
            sceneView.scene?.rootNode.addChildNode(textNode)

            // Optionally: Add an animation or fade-in effect for better UX
            textNode.opacity = 0.0
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            textNode.opacity = 1.0
            SCNTransaction.commit()

            // Mark this constellation name as displayed
            displayedConstellationNames.insert(constellationName)
        } else {
            print("No midpoint found for node \(node.name ?? "unknown")")
        }
    }

    func removeConstellationName(constellationName: String) {
        // Remove the text node displaying the constellation name
        sceneView.scene?.rootNode.enumerateChildNodes { (node, _) in
            if let type = node.value(forKey: "type") as? String, type == "constellationText", node.name == constellationName {
                node.removeFromParentNode()
            }
        }
        
        // Remove the constellation name from the set of displayed names
        displayedConstellationNames.remove(constellationName)
    }


    func removePreviousConstellationNames() {
        sceneView.scene?.rootNode.enumerateChildNodes { (node, _) in
            if node.value(forKey: "type") as? String == "constellationText" {
                node.removeFromParentNode() // Remove any previous constellation text nodes
            }
        }
        displayedConstellationNames.removeAll() // Clear the set
    }

    func drawLineBetweenStars(node1: SCNNode, node2: SCNNode, constellationName: String) {
        let startPos = node1.worldPosition
        let endPos = node2.worldPosition

        let vertices: [SCNVector3] = [startPos, endPos]
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let indices: [UInt32] = [0, 1]
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: 1, bytesPerIndex: MemoryLayout<UInt32>.size)

        let lineGeometry = SCNGeometry(sources: [vertexSource], elements: [element])
        lineGeometry.firstMaterial?.diffuse.contents = UIColor.white

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.name = constellationName

        if drawingModeEnabled {
            lineNode.setValue("customConstellationLine", forKey: "type")
        } else {
            lineNode.setValue("defaultConstellationLine", forKey: "type")
        }

        let midX = (startPos.x + endPos.x) / 2
        let midY = (startPos.y + endPos.y) / 2
        let midZ = (startPos.z + endPos.z) / 2
        let midpoint = SCNVector3(midX, midY, midZ)
        lineNode.setValue(NSValue(scnVector3: midpoint), forKey: "midpoint")

        sceneView.scene?.rootNode.addChildNode(lineNode)
        
        // Add the line node to the current session array
        currentSessionLines.append(lineNode)
    }


    
    func setupCamera(scene: SCNScene) {
        // Create a camera node
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.1  // Set zNear to a small value (e.g., 0.1)
        cameraNode.position = SCNVector3(0, 0, 0) // Move the camera back a bit
        // Enable bloom effect to make bright objects glow
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.exposureOffset = -4
        cameraNode.camera?.bloomIntensity = 0.5
        cameraNode.camera?.bloomThreshold = 0
        cameraNode.camera?.bloomBlurRadius = 5.0
        
        cameraNode.camera?.zFar = 10000.0  // Set zFar to a very high value
        cameraNode.camera?.fieldOfView = 45 // Narrower FOV for a more zoomed-in effect



        scene.rootNode.addChildNode(cameraNode)
    }
            
    func addStarsAndConstellationsToScene(stars: [Star], constellationData: [Constellation]) -> [SCNNode] {
        var starNodes: [SCNNode] = []
        let scene = self.sceneView.scene!
        
        // First, add the stars to the scene
        for star in stars {
            if (star.y_normalized > 0) {
               let starNode = addStar(star, to: scene)
               starNodes.append(starNode)
           }
        }
        
        // Check the toggle button's state and only show constellations if it's selected
        let shouldShowConstellations = constellationToggleButton.isSelected
        
        // Add lines for constellations based on their line coordinates
        for constellation in constellationData {
            var shouldDisplayConstellation = true // Flag to determine if the constellation should be displayed

            for line in constellation.lines {
                // Check the positions of the stars for this line
                let startY = line.startY
                let endY = line.endY

                // If either star in the line is below -0.3 on the Y-axis, skip this constellation
                if startY < 0 || endY < 0 {
                    shouldDisplayConstellation = false
                    break // No need to check further, skip this constellation
                }
            }

            // Only draw the constellation if all stars have Y values greater than -0.3
            if shouldDisplayConstellation {
                for line in constellation.lines {
                    // Create two nodes to represent the start and end positions of the line
                    let startNode = SCNNode()
                    startNode.position = SCNVector3(line.startX * 100, line.startY * 100, line.startZ * 100)

                    let endNode = SCNNode()
                    endNode.position = SCNVector3(line.endX * 100, line.endY * 100, line.endZ * 100)

                    // Draw the line between the two positions
                    drawLineBetweenStars(node1: startNode, node2: endNode, constellationName: constellation.constellationName)
                }
            }
        }

        // Hide constellations if the toggle is not selected
        if !shouldShowConstellations {
            scene.rootNode.enumerateChildNodes { (node, _) in
                if let type = node.value(forKey: "type") as? String,
                   type == "defaultConstellationLine" || type == "constellationText" {
                    node.isHidden = true
                }
            }
        }
        
        return starNodes
    }


        
    func addStar(_ star: Star, to scene: SCNScene) -> SCNNode {
        let normalizedX = star.x_normalized
        let normalizedY = star.y_normalized
        let normalizedZ = star.z_normalized
        
        if normalizedY > 0 {
//            let adjustedRadius = pow(star.normalized_radius, 1.6) * 50
            let adjustedRadius = log(1 + star.normalized_radius * 300) * 0.004
//            let adjustedRadius = pow(star.normalized_radius, 0.8) * 1.5;
            let color = UIColor.white
            
            let starGeometry = SCNSphere(radius: CGFloat(100 * adjustedRadius))
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.emission.contents = color
            material.emission.intensity = 1.0
            material.lightingModel = .constant
            starGeometry.firstMaterial = material
            
            let starNode = SCNNode(geometry: starGeometry)
            starNode.position = SCNVector3(100 * normalizedX, 100 * normalizedY, 100 * normalizedZ)
            
            // Only set the name if it is not nil
            if let starName = star.name {
                starNode.name = starName
            }
            
            // Store metadata
            starNode.setValue(star.distance_pc, forKey: "distance")
            starNode.setValue(star.apparent_magnitude, forKey: "apparent_magnitude")
            starNode.setValue(star.temperature_celsius, forKey: "temperature_celsius")

            // Add hit test geometry if needed (for small stars)
            if CGFloat(adjustedRadius) < 2.0 {
                let hitTestGeometry = SCNSphere(radius: 2.0)
                let hitTestMaterial = SCNMaterial()
                hitTestMaterial.diffuse.contents = UIColor.clear
                hitTestMaterial.emission.contents = UIColor.clear
                hitTestMaterial.transparency = 0.0
                hitTestMaterial.isDoubleSided = true
                hitTestGeometry.firstMaterial = hitTestMaterial
                
                let hitTestNode = SCNNode(geometry: hitTestGeometry)
                hitTestNode.position = SCNVector3Zero
                hitTestNode.name = starNode.name // Same name for identification
                hitTestNode.setValue(star.distance_pc, forKey: "distance")
                hitTestNode.setValue(star.apparent_magnitude, forKey: "apparent_magnitude")
                hitTestNode.setValue(star.temperature_celsius, forKey: "temperature_celsius")

                starNode.addChildNode(hitTestNode)
            }
            
            // Add the starNode to the scene
            scene.rootNode.addChildNode(starNode)
            
            return starNode // Return the created star node
        }
        
        return SCNNode() // Return an empty node in case the star doesn't meet the condition (though this is optional)
    }


    // Add pan and pinch gesture recognizers for camera control
    func addGestureRecognizers() {
        // Pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        // Pinch gesture
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
//        sceneView.addGestureRecognizer(pinchGesture)
    }
    
    // Define rotation limits (in radians)
    let minVerticalAngle: Float = -Float.pi / 8        // Limit looking down to the horizon (0° - 90°)
    let maxVerticalAngle: Float = Float.pi / 2              // Limit looking up to 90°
    
    @objc func handlePanGesture(_ gestureRecognize: UIPanGestureRecognizer) {
        isTapGesture = false // If pan gesture is recognized, it's not a tap
        let translation = gestureRecognize.translation(in: sceneView)
        
        // Calculate horizontal and vertical rotation based on gesture
        let anglePanX = -Float(translation.x) * (Float.pi / 180) * 0.1
        let anglePanY = -Float(translation.y) * (Float.pi / 180) * 0.1
        
        // Apply horizontal (y-axis) rotation without limits (360°)
        cameraNode.eulerAngles.y += anglePanX
        
        // Apply vertical (x-axis) rotation and clamp within limits
        cameraNode.eulerAngles.x = max(min(cameraNode.eulerAngles.x + anglePanY, maxVerticalAngle), minVerticalAngle)

        // Reset translation after applying the rotation
        gestureRecognize.setTranslation(CGPoint.zero, in: sceneView)
    }

    // Handle pinch gesture for zooming in and out
//    @objc func handlePinchGesture(_ gestureRecognize: UIPinchGestureRecognizer) {
//        let zoomFactor = Float(gestureRecognize.scale)
//        
//        // Adjust the camera's position to zoom in or out
//        let currentZ = cameraNode.position.z
//        let newZ = currentZ / zoomFactor
//        
//        cameraNode.position.z = max(min(newZ, 0), 100) // Limit zoom levels between a range
//        
//        gestureRecognize.scale = 1.0 // Reset scale
//    }
}


extension UIColor {
    /// Initialize UIColor with RGB values from 0 to 255 and an optional alpha
    convenience init(rgbRed: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.init(red: rgbRed / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
}
