//
//  MapViewController.swift
//  RoamDemo
//
//  Created by Roam on 09/11/23.
//

import UIKit
import MapKit
import Roam

class MapViewController: UIViewController {
    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.showsUserLocation = true // Show the blue dot for user's location
        return mapView
    }()

    let logoutButton: UIButton = {
        let button = UIButton()
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var loginType: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateMapView), name: Notification.Name("DidUpdateLocations"), object: nil)
        view.backgroundColor = .white

        // Add MapView
        view.addSubview(mapView)
        mapView.frame = view.bounds

        // Add Logout Button at the bottom
        view.addSubview(logoutButton)
        NSLayoutConstraint.activate([
            logoutButton.heightAnchor.constraint(equalToConstant: 60),
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -0),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        
        if loginType == "LoginWithUser" {
            RoamHelper.shared.setupRoam { error in
                print(error)
            }
        }else if loginType == "LoginWithOutUser" { //Custom MQTT
            RoamHelper.shared.registerConnector()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
      deinit {
          NotificationCenter.default.removeObserver(self)
      }

    @objc func logoutButtonTapped() {
        RoamHelper.shared.stopTracking { [weak self] _ in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc func updateMapView() {
        // Update the map view with the latest locations from RoamHelper
        let receivedLocations = RoamHelper.shared.locations

        // Get the new annotation based on the last received location
        let newLocation = receivedLocations.last
        guard let newAnnotation = createAnnotation(for: newLocation) else {
            return
        }

        // Add the new annotation to the map
        mapView.addAnnotation(newAnnotation)

        // Remove old annotations (excluding the new one)
        let annotationsToRemove = mapView.annotations.filter { $0 !== newAnnotation }
        mapView.removeAnnotations(annotationsToRemove)

        // Zoom the map to display all annotations
        zoomMapToDisplayAnnotations()
    }

    func createAnnotation(for location: RoamLocation?) -> MKPointAnnotation? {
        guard let location = location else {
            return nil
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: location.location.coordinate.latitude, longitude: location.location.coordinate.longitude)
        return annotation
    }
    
    func zoomMapToDisplayAnnotations() {
        let annotations = mapView.annotations
          guard !annotations.isEmpty else {
              return // No annotations to display
          }

          var zoomRect = MKMapRect.null

          for annotation in annotations {
              let annotationPoint = MKMapPoint(annotation.coordinate)
              let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0, height: 0)
              zoomRect = zoomRect.union(pointRect)
          }

          let region = MKCoordinateRegion(zoomRect)

          // Adjust the span for a medium zoom level
          let adjustedRegion = MKCoordinateRegion(
              center: region.center,
              span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
          )

          mapView.setRegion(adjustedRegion, animated: true)
      }
}
