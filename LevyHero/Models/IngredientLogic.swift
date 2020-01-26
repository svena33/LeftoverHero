//
//  IngredientLogic.swift
//  LevyHero
//
//  Created by Sven Arends on 31/12/2019.
//  Copyright © 2019 Sven Arends. All rights reserved.
//

import Foundation

//
protocol IngredientLogicDelegate {
    func newIngredientAdded(_ ingredientLogic: IngredientLogic, newIng: String)
}

struct IngredientLogic{
    
    // ingredientList of selected ingredients
    private var selectedIngredientList: [String] = []
    
    //full ingredient list (including deselected ingredients)
    private var fullIngredientList: [String] = []
     
    var delegate: IngredientLogicDelegate?
    
    func getSelectedIngredients()->[String]{
        return selectedIngredientList
    }
    
    //remove elements for the selectedIngredients list
    mutating func deselectIngredient(_ ingredient:String){
        if let index = selectedIngredientList.firstIndex(of: ingredient) {
            selectedIngredientList.remove(at: index)
        }
    }
    
    //add elements to the selectedIngredients list
    mutating func selectIngredient(_ ingredient:String){
        selectedIngredientList.append(ingredient)
    }

    //an ingredient was detected in frame
    mutating func addIngredient(_ newIngredient:String){
        if !fullIngredientList.contains(newIngredient){
            //new ingredient was detected
            fullIngredientList.append(newIngredient)
            selectedIngredientList.append(newIngredient)

            delegate?.newIngredientAdded(self, newIng: newIngredient)
        }else{
            //ingredient was already part of the (full)ingredientList
        }
    }
    
    mutating func removeIngredient(_ rmIngredient:String){
        if let index = selectedIngredientList.firstIndex(of: rmIngredient) {
            selectedIngredientList.remove(at: index)
        }
        if let index = fullIngredientList.firstIndex(of: rmIngredient) {
            fullIngredientList.remove(at: index)
        }
    }
}
