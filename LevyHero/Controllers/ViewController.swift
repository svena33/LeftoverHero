//
//  ViewController.swift
//  LevyHero
//
//  Created by Sven Arends on 22/12/2019.
//  Copyright © 2019 Sven Arends. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import SafariServices

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, RecipeModelXIBDelegate{
    
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    
    var networkManager = NetworkManager()
    let NoFetchedRecipes = 5
    var ingredientLogicManager = IngredientLogic()
    
    //RecipeCards decleration
    private var xposition: Int = 0
    private var newCardWidth: Int = 0
    private var cardSpacer:Int = 0
    private var recipecardViews: [RecipeModelXIB] = []
    private var scrollHRecipesContentSize:CGFloat=0;
    
    //IngredientsButton Setup
    private var xPositionIngredients:CGFloat = 10
    private var scrollViewIngredientsContentSize:CGFloat=0;
    
    
    @IBOutlet weak private var previewView: UIView!
    @IBOutlet weak private var scrollHIngredients: UIScrollView!
    @IBOutlet weak private var scrollHRecipes: UIScrollView!
    @IBOutlet weak private var recipeActivityIndicator: UIActivityIndicatorView!
    
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer! = nil
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Select a video device, make an input
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480 // Model image size is smaller.
        
        // Add a video input
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            // Add a video data output
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        let captureConnection = videoDataOutput.connection(with: .video)
        // Always process the frames
        captureConnection?.isEnabled = true
        do {
            try  videoDevice!.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        rootLayer = previewView.layer
        previewLayer.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //RecipeCards setup
        xposition = (Int(self.view.frame.width)/10)
        newCardWidth = Int(self.view.frame.width*0.6)
        cardSpacer = newCardWidth + 50
        
        styleUIElements()
        
        networkManager.delegate = self
        ingredientLogicManager.delegate = self
        #if targetEnvironment(simulator)
        ingredientLogicManager.addIngredient("Onion")
        ingredientLogicManager.addIngredient("Tomato")

        #else
        setupAVCapture()
        #endif
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Add rounding and effects to UIElements
    func styleUIElements(){
        scrollHIngredients.layer.cornerRadius = 30
        scrollHIngredients.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    @objc func IngredientBtnPressed(sender: UIButton) {
        print("Button Pressed: \(sender.titleLabel?.text! ?? "titleLabel button undefined")")
        toggleIngredientsSelection(sender: sender)
    }
    
    @objc func searchRecipeWeb(_ recipe: String?){
        //open google search to find recipe
        let recipeName = recipe
        let urlString = "https://google.com/search?&q=\(recipeName!.replacingOccurrences(of: " ", with: "+"))"
        
        //if valid URL, present a safari view controller with the search querry
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
        
        
    }
    
    
    func toggleIngredientsSelection(sender: UIButton){
        //define how transparent the button should if the ingredient is deselected
        let inactiveAlpha = CGFloat(0.2)
        
        var newAlpha: CGFloat
        
        if (sender.alpha != 1){
            newAlpha = 1
            ingredientLogicManager.selectIngredient((sender.titleLabel?.text!)!)
        }else{
            newAlpha = inactiveAlpha
            ingredientLogicManager.deselectIngredient((sender.titleLabel?.text!)!)
        }
        
        //set button transparancy to target transparancy
        sender.alpha = newAlpha
        
        // set all related views to an equal alpha
        for view in sender.superview!.subviews{//we can safely force unwrap since this button added to a superview on creation
            view.alpha = newAlpha
        }
        
        //fetch recipes for currently selected ingredients
        networkManager.fetchRecipes(ingredients: ingredientLogicManager.getSelectedIngredients(), numberOfRecipes: NoFetchedRecipes)
    }
    
}

//MARK: - Create and Add Ingredient buttons and Recipe Cards
extension ViewController{
    
    //populate blank card with recipe data
    func createNewRecipeCard(newRecipe: RecipeModel, index: Int){
        //space between
        
        let height = Int(scrollHRecipes.frame.size.height/1.5)
        let startY = Int(scrollHRecipes.frame.size.height/8)
        
        //Create new Card
        let newx = xposition + cardSpacer*index
        let customView:RecipeModelXIB = RecipeModelXIB(frame: CGRect(x: newx, y:startY, width: newCardWidth, height:height))
        
        if let safeImage = newRecipe.image{ //check if an image is available
            let myImage:UIImage = UIImage(data: safeImage)!
            customView.setup(vc: self, recipeName: newRecipe.name, recipeImage: myImage)
        }else{
            customView.setup(vc: self, recipeName: newRecipe.name, recipeImage: nil)
        }
        
        addNewCard(customView)
    }
    
    //get all recipeCards and remove them
    func destroyRecipeCards(){
        for v in recipecardViews{
            v.removeFromSuperview()
        }
    }
    
    //add newly created card to the view
    func addNewCard(_ newCard: RecipeModelXIB) {
        recipecardViews.append(newCard)
        scrollHRecipes.addSubview(newCard)
        scrollHRecipesContentSize+=CGFloat(cardSpacer)
        scrollHRecipes.contentSize =  CGSize(width: scrollHRecipesContentSize, height: CGFloat(newCard.frame.height))
    }
    
    
    //Create a new ingredient button.
    func createIngredientButton(newIngredientName: String){
        let imageWidth:CGFloat = 60
        let uiLabelHeight:CGFloat = 30
        let ingredientSpacer:CGFloat = 20
        
        
        let newIngredientContainerView = UIView(frame: CGRect(x: xPositionIngredients+10, y: 10, width: imageWidth, height: imageWidth+uiLabelHeight))
        
        //Create Background Image for the buttons
        let myImage:UIImage = UIImage(named: newIngredientName)!
        let myImageView:UIImageView = UIImageView()
        myImageView.image = myImage
        
        //Create the button for the next ingredient
        let newButton = UIButton()
        newButton.titleLabel!.text = newIngredientName
        newButton.frame = CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth)
        newButton.setImage(myImage, for: .normal)
        newButton.addTarget(self, action: #selector(IngredientBtnPressed), for: .touchUpInside)
        newButton.layer.cornerRadius = imageWidth/2
        newButton.clipsToBounds = true
        
        //Attach a UILabel
        let uiLabel = UILabel(frame: CGRect(x: 0, y: 60, width: imageWidth, height: uiLabelHeight))
        uiLabel.text = newIngredientName
        uiLabel.textAlignment = .center
        
        addNewIngredientBtnScrollView(newIngredientContainerView, uiLabel, newButton, imageWidth, ingredientSpacer)
    }
    
    //Add newly created card to the ingredient scroll view
    func addNewIngredientBtnScrollView(_ newIngredientContainerView: UIView, _ uiLabel: UILabel, _ newButton: UIButton, _ imageWidth: CGFloat, _ ingredientSpacer: CGFloat) {
        
        //add label and button to container view
        newIngredientContainerView.addSubview(uiLabel)
        newIngredientContainerView.addSubview(newButton)
        
        //Add container view to scroll View
        scrollHIngredients.addSubview(newIngredientContainerView)
        scrollHIngredients.clipsToBounds=true
        
        
        xPositionIngredients+=imageWidth + ingredientSpacer
        scrollViewIngredientsContentSize+=imageWidth + ingredientSpacer
        //resize ingredients scroll view
        scrollHIngredients.contentSize = CGSize(width: scrollViewIngredientsContentSize, height: imageWidth)
    }
}

//MARK: - Add ingredient on detection
extension ViewController: IngredientLogicDelegate{
    
    //Fetch new recipes when new ingredients are detected
    func newIngredientAdded(_ ingredientLogic: IngredientLogic, newIng: String) {
        
        //Add ingredient button when an ingredient is detected
        createIngredientButton(newIngredientName: newIng)
        
        //fetch new recipes
        networkManager.fetchRecipes(ingredients: ingredientLogic.getSelectedIngredients(), numberOfRecipes: NoFetchedRecipes)
        
    }
}

//MARK: - Network request handling
extension ViewController: NetworkManagerDelegate{
    // Recipe List was muted, thus we trigger an update
    func didUpdateRecipeList(_ networkManager: NetworkManager, recipeList: [RecipeModel]) {
        DispatchQueue.main.async { // Perform UI changes on main thread
            self.destroyRecipeCards()
            self.scrollHRecipesContentSize = 0
            self.recipeActivityIndicator.stopAnimating()
            
            for (idx,r) in recipeList.enumerated(){
                //create a new Recipe card for each recipe when the list has been received
                self.createNewRecipeCard(newRecipe: r, index: idx)
            }
        }
    }
    
    func didFailWithError(error: Error) {
        print(error)
    }
}
//MARK: - Setup the AV Capture
extension ViewController{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // to be implemented in the subclass
    }
    
    func startCaptureSession() {
        session.startRunning()
    }
    
    func toggleSessionActive(){
        if (session.isRunning){
            session.stopRunning()
        }else{
            session.startRunning()
        }
    }
    
    // Clean up capture setup
    func teardownAVCapture() {
        previewLayer.removeFromSuperlayer()
        previewLayer = nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print("frame dropped")
    }
    
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
        switch curDeviceOrientation {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }
        return exifOrientation
    }
}

//Add borderWidth, cornerRadius and borderColor to Storyboard Inspector
@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}
