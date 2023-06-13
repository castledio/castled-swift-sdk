//
//  CastledInAppModalViewController.swift
//  Castled
//
//  Created by Faisal Azeez on 12/12/2022.
//

import UIKit

class CastledInAppModalViewController: UIViewController {
    
    @IBOutlet weak var constraintImageHeight: NSLayoutConstraint!
    var parentContainerVC: CastledInAppDisplayViewController?
    var inAppDisplaySettings : InAppDisplayConfig?
    var mainImage : UIImage?
    
    @IBOutlet weak var viewMainContainer: UIView!
    
    @IBOutlet weak var imgClose: UIImageView!
    
    @IBOutlet weak var viewImageContainer: UIView!
    @IBOutlet weak var imgViewMain: UIImageView!
    
    @IBOutlet weak var viewTitleContainer: UIView!
    @IBOutlet weak var lblMessageTitle: UILabel!
    
    @IBOutlet weak var viewDetailContainer: UIView!
    @IBOutlet weak var lblMessageSubTitle: UILabel!
    
    @IBOutlet weak var btnCloseView: UIButton!
    @IBOutlet weak var btnLeftOfView: UIButton!
    @IBOutlet weak var btnRightOfView: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    /**
     Popultaing the contents and UI
     */
    private func setupViews() {
        
        
        lblMessageTitle.font = inAppDisplaySettings?.titleFont.withSize(CGFloat(inAppDisplaySettings!.titleFontSize))
        lblMessageSubTitle.font = inAppDisplaySettings?.bodyFont.withSize(CGFloat(inAppDisplaySettings!.bodyFontSize))
        btnLeftOfView.titleLabel?.font = inAppDisplaySettings?.buttonFont.withSize(CGFloat(inAppDisplaySettings!.bodyFontSize - 1))
        btnRightOfView.titleLabel?.font = btnLeftOfView.titleLabel?.font
        
        viewMainContainer.layer.cornerRadius = 5
        lblMessageTitle.textColor = inAppDisplaySettings?.titleFontColor
        lblMessageSubTitle.textColor = inAppDisplaySettings?.bodyFontColor
        btnLeftOfView.setTitleColor(inAppDisplaySettings?.leftButtonFontColor, for: .normal)
        btnLeftOfView.backgroundColor = inAppDisplaySettings?.leftButtonColor
        btnRightOfView.setTitleColor(inAppDisplaySettings?.rightButtonFontColor, for: .normal)
        btnRightOfView.backgroundColor = inAppDisplaySettings?.rightButtonColor
        viewTitleContainer.backgroundColor = inAppDisplaySettings?.titleBgColor
        viewDetailContainer.backgroundColor = inAppDisplaySettings?.bodyBgColor
        view.backgroundColor = inAppDisplaySettings?.screenOverlayColor
        let closeImage = imgClose.image?.withRenderingMode(.alwaysTemplate)
        imgClose.image = closeImage
        imgClose.tintColor = .white
        imgClose.backgroundColor = UIColor.gray.withAlphaComponent(0.9)
        imgClose.layer.cornerRadius = imgClose.frame.size.height/2
        imgClose.addShadow(radius: 5, opacity: 0.6, offset: CGSize(width: 0, height: 2), color: UIColor.black)
        
        
        imgViewMain.image = mainImage
      
        
        if let color = inAppDisplaySettings?.leftButtonBorderColor{
            btnLeftOfView.layer.borderColor = color.cgColor
            btnLeftOfView.layer.borderWidth = CGFloat(inAppDisplaySettings!.leftButtonBorderWidth)
            btnLeftOfView.layer.cornerRadius = CGFloat(inAppDisplaySettings!.leftButtonCornerRadius)
            
        }
        
        if let color = inAppDisplaySettings?.rightButtonBorderColor{
            btnRightOfView.layer.borderColor = color.cgColor
            btnRightOfView.layer.borderWidth = CGFloat(inAppDisplaySettings!.rightButtonBorderWidth)
            btnRightOfView.layer.cornerRadius = CGFloat(inAppDisplaySettings!.rightButtonCornerRadius)
            
        }
        
        lblMessageTitle.text = inAppDisplaySettings?.title
        lblMessageSubTitle.text = inAppDisplaySettings?.body
        
        btnLeftOfView.setTitle(inAppDisplaySettings?.leftButtonTitle, for: .normal)
        btnRightOfView.setTitle(inAppDisplaySettings?.rightButtonTitle, for: .normal)
        
    }
    
    @IBAction func hideInAppView(_ sender: Any) {
        
        
        CastledInApps.sharedInstance.updateInappEvent(inappObject: (parentContainerVC?.selectedInAppObject)!, eventType: CastledConstants.CastledEventTypes.discarded.rawValue, actionType: nil, btnLabel: nil, actionUri: nil)
        
        parentContainerVC?.hideInAppViewFromWindow(withAnimation: true)
        
        
    }
    
    @IBAction func rightButtonClikdAction(_ sender: Any) {
        
        CastledInApps.sharedInstance.updateInappEvent(inappObject: (parentContainerVC?.selectedInAppObject)!, eventType: CastledConstants.CastledEventTypes.cliked.rawValue,actionType: inAppDisplaySettings?.rightButtonClickAction, btnLabel:inAppDisplaySettings?.rightButtonTitle, actionUri: inAppDisplaySettings?.rightButtonUri)
        CastledInApps.sharedInstance.performButtonActionFor(buttonAction:parentContainerVC?.selectedInAppObject?.message?.modal?.actionButtons.last)
        
        parentContainerVC?.hideInAppViewFromWindow(withAnimation: true)
        
        
    }
    
    @IBAction func leftButtonClikdAction(_ sender: Any) {
        CastledInApps.sharedInstance.updateInappEvent(inappObject: (parentContainerVC?.selectedInAppObject)!, eventType: CastledConstants.CastledEventTypes.cliked.rawValue,actionType: inAppDisplaySettings?.leftButtonClickAction, btnLabel:inAppDisplaySettings?.leftButtonTitle, actionUri: inAppDisplaySettings?.leftButtonUri)
        CastledInApps.sharedInstance.performButtonActionFor(buttonAction:parentContainerVC?.selectedInAppObject?.message?.modal?.actionButtons.first)
        
        parentContainerVC?.hideInAppViewFromWindow(withAnimation: true)
    }
}
