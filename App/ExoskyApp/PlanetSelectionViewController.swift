//
//  PlanetSelectionViewController.swift
//  ExoskyApp
//
//  Created by Chaehyun Park on 10/6/24.
//

import UIKit

class PlanetSelectionViewController: UIViewController {

    let leftBannerButton = UIButton()
    let rightBannerButton = UIButton()
    let titleLabel = UILabel() // Add the title label

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPlanetSelection()
    }

    func setupPlanetSelection() {
        // Create and configure the background image view
        let backgroundImageView = UIImageView(image: UIImage(named: "Background")) // Replace with your image name
        backgroundImageView.contentMode = .scaleAspectFill // Adjust the image view to fill the entire view
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView) // Add it first, so it's behind everything

        // Set constraints for the background image to cover the entire screen
        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Configure the title label
        titleLabel.text = "Choose an Exoplanet to Explore!"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Load the images
        let glieseImage = UIImage(named: "Gliese")
        let k2Image = UIImage(named: "K2")

        // Configure the left planet button
        leftBannerButton.setBackgroundImage(glieseImage, for: .normal)
        leftBannerButton.translatesAutoresizingMaskIntoConstraints = false
        leftBannerButton.addTarget(self, action: #selector(didSelectKepler438b), for: .touchUpInside)
        view.addSubview(leftBannerButton)

        // Configure the right planet button
        rightBannerButton.setBackgroundImage(k2Image, for: .normal)
        rightBannerButton.translatesAutoresizingMaskIntoConstraints = false
        rightBannerButton.addTarget(self, action: #selector(didSelectK218b), for: .touchUpInside)
        view.addSubview(rightBannerButton)

        // Set constraints for layout
        NSLayoutConstraint.activate([
            // Constraints for the title label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Constraints for the left planet button with aspect ratio based on height
            leftBannerButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -20), // Align to the left of center
            leftBannerButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30), // Below the title label
            leftBannerButton.heightAnchor.constraint(equalToConstant: 250), // Set height
            leftBannerButton.widthAnchor.constraint(equalTo: leftBannerButton.heightAnchor, multiplier: (glieseImage?.size.width ?? 1.0) / (glieseImage?.size.height ?? 1.0)), // Maintain aspect ratio based on height

            // Constraints for the right planet button with aspect ratio based on height
            rightBannerButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 20), // Align to the right of center
            rightBannerButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30), // Below the title label
            rightBannerButton.heightAnchor.constraint(equalToConstant: 250), // Set height
            rightBannerButton.widthAnchor.constraint(equalTo: rightBannerButton.heightAnchor, multiplier: (k2Image?.size.width ?? 1.0) / (k2Image?.size.height ?? 1.0)) // Maintain aspect ratio based on height
        ])
    }

    @objc func didSelectKepler438b() {
        // Load Kepler-438b JSON files (mag4 to mag8)
        loadStars(forPlanet: "Gliese_581")
    }

    @objc func didSelectK218b() {
        // Load K2-18b JSON files (mag4 to mag8)
        loadStars(forPlanet: "K2-18")
    }

    func loadStars(forPlanet planetPrefix: String) {
        let starViewController = ViewController() // Replace with your main star scene view controller

        // Pass the selected planet's JSON files to the star view controller
        starViewController.loadAllStars(forPlanet: planetPrefix) { [weak self] success in
            if success {
                // Only present the view controller after loading is complete
                DispatchQueue.main.async {
                    starViewController.modalPresentationStyle = .fullScreen
                    self?.present(starViewController, animated: true, completion: nil)
                }
            } else {
                print("Error loading stars.")
            }
        }
    }

    // Lock orientation to landscape
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight // Forces the view to landscape with home button on the right
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
