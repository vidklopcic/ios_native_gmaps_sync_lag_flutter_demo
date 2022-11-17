import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    lazy var flutterEngine = FlutterEngine(name: "Demo Flutter engine")
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        flutterEngine.run();

        GMSServices.provideAPIKey("AIzaSyAR6Q1EU9nyDot1KJ8XniZC8LFCxx3SzT4")

        GeneratedPluginRegistrant.register(with: self.flutterEngine)

        window = AppWindow()
        window!.rootViewController = GoogleMapsViewController()
        window!.makeKeyAndVisible()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

class AppWindow: UIWindow {
    override func sendEvent(_ event: UIEvent) {
        var controller = self.rootViewController as! GoogleMapsViewController
        controller.onInterceptedEvents(event)
        super.sendEvent(event)
    }
}


class GoogleMapsViewController: UIViewController, GMSMapViewDelegate {
    var mapView: GMSMapView?
    var flutterViewController: FlutterViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withLatitude: 46.0569, longitude: 14.5058, zoom: 11.5)
        mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        mapView!.delegate = self
        mapView!.isTrafficEnabled = true;
        self.view.addSubview(mapView!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let flutterEngine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine
        flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        flutterViewController!.view.frame = UIScreen.main.bounds // or use window .frame
        flutterViewController!.view.backgroundColor = UIColor(white: 1, alpha: 0)
        flutterViewController!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        flutterViewController!.view.isUserInteractionEnabled = false;
        self.view.addSubview(flutterViewController!.view)
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        var data = Data()
        data.append(withUnsafeBytes(of: Float64(position.target.latitude)) { Data($0) })
        data.append(withUnsafeBytes(of: Float64(position.target.longitude)) { Data($0) })
        data.append(withUnsafeBytes(of: Float32(position.zoom)) { Data($0) })
        data.append(withUnsafeBytes(of: Float32(position.bearing)) { Data($0) })
        self.flutterViewController!.binaryMessenger.send(onChannel: "com.vidklopcic.ios_native_gmaps_sync_lag_flutter_demo/maps", message: data)
    }
    
    func onInterceptedEvents(_ event: UIEvent) {
        let touches = event.allTouches!
        flutterViewController!.view.touchesBegan(touches.filter { $0.phase == .began }, with: event)
        flutterViewController!.view.touchesMoved(touches.filter { $0.phase == .moved }, with: event)
        flutterViewController!.view.touchesEnded(touches.filter { $0.phase == .ended }, with: event)
        flutterViewController!.view.touchesCancelled(touches.filter { $0.phase == .cancelled }, with: event)
    }
}
