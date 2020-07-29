//
//  ViewController.swift
//  websocketTest
//
//  Created by Greg Mardon on 2020-07-28.
//

import UIKit
import MapKit
import Starscream

class PlaneAnnotation : NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    init(coordinate:CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

class ViewController: UIViewController {

    var jsonDecoder = JSONDecoder.init()
    
    var socket:WebSocket?
    
    var planeView: MKAnnotationView!
    
    var lastLatitude:Double?  = nil
    var lastLongitude:Double? = nil
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        mapView.addAnnotation(PlaneAnnotation.init(coordinate: CLLocationCoordinate2D.init(latitude: 51,longitude: -114)))
        
        var request = URLRequest(url: URL(string: "ws://localhost:4444/arinc834?params=param2,param3")!)
//        request.httpBody = "Test".data(using: .utf8)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket!.delegate = self
        socket!.connect()
    }
    
    func process(params:[A834DataParameter]){
        for param in params {
            if param.parameterName == "LatitudeHighPrecision" {
                lastLatitude = Double(param.value)

            }else if param.parameterName == "LongitudeHightPrecision" {
                lastLongitude = Double(param.value)
            } else if param.parameterName == "IrsTrueHeading" {
                let heading = Double(param.value)
                planeView?.transform = CGAffineTransform( rotationAngle: CGFloat( ((heading ?? 0) / 360.0) * .pi ) )
            }
        }
        
        if lastLatitude != nil && lastLongitude != nil {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    (self.planeView.annotation as? PlaneAnnotation)?.coordinate = CLLocationCoordinate2DMake(self.lastLatitude!, self.lastLongitude!)
                }
            }
            
        }
    }
}

extension ViewController : WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
//            isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
//            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            do {
                let jsonData = string.data(using: .utf8)
                guard jsonData != nil else {
                    return
                }
                let params = try self.jsonDecoder.decode([A834DataParameter].self, from: jsonData!)
                process(params: params)
            }catch
            {
                print("Unable to decode message from websocket \(error)")
            }
            
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("is cancelled")
        case .error(let error):
            if error != nil {
                print(error!)
            }
        }
    }
    
    
}

extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is PlaneAnnotation {
            let pin = mapView.view(for: annotation) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
            pin.image = UIImage(named: "plane_sm.png")
            self.planeView = pin
            return pin

        } else {
            // handle other annotations

        }
        return nil
    }
}
