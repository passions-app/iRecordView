//
//  RecordView.swift
//  iRecordView
//
//  Created by Devlomi on 8/3/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

public class RecordView: UIView, CAAnimationDelegate {

    private var isSwiped = false
    private var bucketImageView: BucketImageView!

    private var timer: Timer?
    private var duration: CGFloat = 0
    private var mTransform: CGAffineTransform!
    private var audioPlayer: AudioPlayer!
    
    private(set) public var timerStackView: UIStackView!
    private var slideToCancelStackVIew: UIStackView!

    public var delegate: RecordViewDelegate?
    public var offset: CGFloat = 20
    public var isSoundEnabled = true

    public var slideToCancelText: String! {
        didSet {
            slideLabel.text = slideToCancelText
        }
    }

    public var slideToCancelTextColor: UIColor! {
        didSet {
            slideLabel.textColor = slideToCancelTextColor
        }
    }

    public var slideToCancelArrowImage: UIImage! {
        didSet {
            arrow.image = slideToCancelArrowImage
        }
    }

    public var smallMicImage: UIImage! {
        didSet {
            bucketImageView.smallMicImage = smallMicImage
        }
    }

    public var durationTimerColor: UIColor! {
        didSet {
            timerLabel.textColor = durationTimerColor
        }
    }


    public let arrow: UIImageView = {
        let arrowView = UIImageView()
        arrowView.image = UIImage.fromPod("arrow")
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.tintColor = .black
        return arrowView
    }()

    public let slideLabel: UILabel = {
        let slide = UILabel()
        slide.text = "Slide To Cancel"
        slide.translatesAutoresizingMaskIntoConstraints = false
        slide.font = slide.font.withSize(12)
        return slide
    }()

    public var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = label.font.withSize(12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    


    private func setup() {
        bucketImageView = BucketImageView(frame: frame)
        bucketImageView.animationDelegate = self
        bucketImageView.translatesAutoresizingMaskIntoConstraints = false

        timerStackView = UIStackView(arrangedSubviews: [bucketImageView, timerLabel])
        timerStackView.translatesAutoresizingMaskIntoConstraints = false
        timerStackView.isHidden = true
        timerStackView.spacing = 5
        timerLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        bucketImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        bucketImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        bucketImageView.setContentHuggingPriority(.required, for: .horizontal)

        slideToCancelStackVIew = UIStackView(arrangedSubviews: [slideLabel, arrow])
        slideToCancelStackVIew.translatesAutoresizingMaskIntoConstraints = false
        slideToCancelStackVIew.isHidden = true
        slideToCancelStackVIew.spacing = 5


        addSubview(timerStackView)
        addSubview(slideToCancelStackVIew)


        arrow.contentMode = .scaleAspectFit

        slideToCancelStackVIew.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        slideToCancelStackVIew.bottomAnchor.constraint(greaterThanOrEqualTo: self.bottomAnchor).isActive = true
        slideToCancelStackVIew.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor).isActive = true
        slideToCancelStackVIew.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true


        timerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        timerStackView.bottomAnchor.constraint(greaterThanOrEqualTo: self.bottomAnchor).isActive = true
        timerStackView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor).isActive = true
        timerStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true


        mTransform = CGAffineTransform(scaleX: 2.0, y: 2.0)

        audioPlayer = AudioPlayer()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }


    func onTouchDown(recordButton: RecordButton) {
        onStart(recordButton: recordButton)
    }

    func onTouchUp(recordButton: RecordButton) {
        onFinish(recordButton: recordButton)
    }


    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }


    @objc private func updateDuration() {
        duration += 1
        timerLabel.text = duration.fromatSecondsFromTimer()
    }

    //this will be called when user starts tapping the button
    private func onStart(recordButton: RecordButton) {
        resetTimer()

        isSwiped = false
        //start timer
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateDuration), userInfo: nil, repeats: true)


        //reset all views to default
        slideToCancelStackVIew.transform = .identity
        recordButton.transform = .identity

        //animate button to scale up
        UIView.animate(withDuration: 0.2) {
            recordButton.transform = self.mTransform
        }


        slideToCancelStackVIew.isHidden = false
        timerStackView.isHidden = false
        timerLabel.isHidden = false
        bucketImageView.isHidden = false
        bucketImageView.resetAnimations()
        bucketImageView.animateAlpha()

        if isSoundEnabled {
            audioPlayer.playAudioFile(soundType: .start)
        }

        delegate?.onStart()

    }

    //this will be called when user swipes to the left and cancel the record
    private func onSwipe(recordButton: RecordButton) {
        isSwiped = true

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            recordButton.transform = .identity
        })


        slideToCancelStackVIew.isHidden = true
        timerLabel.isHidden = true

        if !isLessThanOneSecond() {
            bucketImageView.animateBucketAndMic()

        } else {
            bucketImageView.isHidden = true
            delegate?.onAnimationEnd?()
        }

        resetTimer()

        delegate?.onCancel()
    }

    private func resetTimer() {
        timer?.invalidate()
        timerLabel.text = "00:00"
        duration = 0
    }

    //this will be called when user lift his finger
    private func onFinish(recordButton: RecordButton) {
        isSwiped = false

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            recordButton.transform = .identity
        })


        slideToCancelStackVIew.isHidden = true
        timerStackView.isHidden = true

        timerLabel.isHidden = true


        if isLessThanOneSecond() {
            if isSoundEnabled {
                audioPlayer.playAudioFile(soundType: .error)
            }
        } else {
            if isSoundEnabled {

                audioPlayer.playAudioFile(soundType: .end)
            }
        }

        delegate?.onFinished(duration: duration)

        resetTimer()

    }


    //this will be called when user starts to move his finger
    func touchMoved(recordButton: RecordButton, sender: UIPanGestureRecognizer) {

        if isSwiped {
            return
        }

        let button = sender.view!
        let translation = sender.translation(in: button)

        switch sender.state {
        case .changed:

            //prevent swiping the button outside the bounds
            if translation.x < 0 {
                //start move the views
                let transform = mTransform.translatedBy(x: translation.x, y: 0)
                button.transform = transform
                slideToCancelStackVIew.transform = transform.scaledBy(x: 0.5, y: 0.5)


                if slideToCancelStackVIew.frame.intersects(timerStackView.frame.offsetBy(dx: offset, dy: 0)) {
                    onSwipe(recordButton: recordButton)
                }

            }

        case .ended:
            onFinish(recordButton: recordButton)


        default:
            break
        }

    }


}


extension RecordView: AnimationFinishedDelegate {
    func animationFinished() {
        slideToCancelStackVIew.isHidden = true
        timerStackView.isHidden = false
        timerLabel.isHidden = true
        delegate?.onAnimationEnd?()
    }
}

private extension RecordView {
    func isLessThanOneSecond() -> Bool {
        return duration < 1
    }
}


