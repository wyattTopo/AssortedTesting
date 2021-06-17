//
//  VolumeListener.swift
//  SystemTools
//
//  Created by Wyatt Eberspacher on 6/17/21.
//

import Foundation
import Combine
import MediaPlayer

public protocol VolumeListenerDelegate: AnyObject {
  func volumeChanged()
}

//Fun note: If spotify is running, and the account is paired with a separate playing device, Spotify seems to submit its own volume change request (applies volume change to all devices), which causes this to fire twice

/// Simple class that contains a volumeView that should be added to a viewController than wishes to use this feature. The delegate will respond to ALL volume change events so long as the VC is presented on screen.
public class VolumeListener {
  var cancellables = [AnyCancellable]()
  
  /// Replaces the default volume view that shows up when the colume changes.
  public let volumeView = MPVolumeView(frame: .zero)
  
  /// Responds to volume changes
  public weak var delegate: VolumeListenerDelegate?
  
  let initialVolume: Float
  
  // Sets up a Combine publisher that is listening to the volume change controller that is triggered by adding MPVolumeView to an active view.
  public init() {
    self.initialVolume = AVAudioSession.sharedInstance().outputVolume
    NotificationCenter.default
      .publisher(for: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"))
      .compactMap { $0.userInfo }
      .sink(receiveValue: { (val) in
        // Only respond if the containing view is still presented on screen, and the input change reason was user input.
        guard
          self.volumeView.superview?.window != nil,
          let reason = val["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String,
          reason == "ExplicitVolumeChange"
        else { return }
        self.delegate?.volumeChanged()
      })
      .store(in: &cancellables)
  }
  
  // Theoreticly, this resets the volume when it being "eaten" by the camera. However, the behavior starts to get weird the navigation stack is considered. For example, if the volume is raised after the view is used, then the view is returned to, the volume would be reset to whatever it was when the view FIRST loaded. Would replace the delgate call above.
  func resetVolume(_ action: @escaping () -> Void) {
    let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) {
      if slider?.value != self.initialVolume {
        slider?.value = self.initialVolume
        self.delegate?.volumeChanged()
      }
    }
  }
}

