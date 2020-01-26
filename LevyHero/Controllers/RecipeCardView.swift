//
//  RecipeCardViewController.swift
//  LevyHero
//
//  Created by Sven Arends on 26/01/2020.
//  Copyright © 2020 Sven Arends. All rights reserved.
//

import UIKit

protocol RecipeModelXIBDelegate {
    func searchRecipeWeb(_ recipe: String?)
}

//Class that controlls the RecipeCardXIB
class RecipeModelXIB: UIView{
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var recipeNameLabel: UILabel!
    @IBOutlet weak var recipeImageButton: UIButton!
    var recName:String?

    var delegate: RecipeModelXIBDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        //Unarchives the contents of the RecipeCard xib file 
        Bundle.main.loadNibNamed("RecipeCard", owner: self, options: nil)

        //set rounded corners for recipe card
        self.layer.cornerRadius = 16
        self.layer.masksToBounds = true
        
        recipeNameLabel.textColor = .black
        addSubview(contentView)
        contentView.frame = self.bounds
    }
    
    func setup(vc: RecipeModelXIBDelegate, recipeName: String, recipeImage: UIImage?){
        delegate = vc
        
        recipeNameLabel.text = recipeName
        recName = recipeName
        //recipeImageButton.setTitle(recipeName, for: .normal)
        if (recipeImage != nil) {
            //add provided Recipe Image as background image for the recipe button
            recipeImageButton.setImage(nil, for: .normal)
            recipeImageButton.setBackgroundImage(recipeImage, for: .normal)
            //set rounded corners for recipe image button
            recipeImageButton.layer.cornerRadius = recipeImageButton.frame.size.height/2
            recipeImageButton.clipsToBounds = true

        }
    }
    
    @IBAction func RecipeImagePressed(_ sender: UIButton) {
        //Trigger google search in RecipeModelXIBDelegate viewcontroller
        delegate?.searchRecipeWeb(recName)
    }
}
