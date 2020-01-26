//
//  NetworkManager.swift
//  LevyHero
//
//  Created by Sven Arends on 30/12/2019.
//  Copyright © 2019 Sven Arends. All rights reserved.
//

import Foundation

protocol NetworkManagerDelegate {
    func didUpdateRecipeList(_ networkManager: NetworkManager, recipeList: [RecipeModel])
    func didFailWithError(error: Error)
}

struct NetworkManager{
    let spoonacularBaseURL = "https://api.spoonacular.com/recipes/findByIngredients?limitLicense=False&ranking=1&ignorePantry=True&apiKey=bea35b1bd5944a849800230ff8924164"
    
    var delegate: NetworkManagerDelegate?
    
    func fetchRecipes(ingredients: [String], numberOfRecipes: Int){
        let noRecipesString = "&number=\(numberOfRecipes)"
        var ingredientString = "&ingredients="
        for ingre in ingredients {
            ingredientString += "," + ingre
        }
        let urlString = spoonacularBaseURL+ingredientString+noRecipesString
        performRequest(with: urlString)
    }
    
    
    func performRequest(with urlString: String){
        //create URL
        if let url = URL(string: urlString){

            //create URL Session
            let session = URLSession(configuration: .default)
            //create the session a task
            //let task = session.dataTask(with: url, completionHandler: handle(data:response:error:))
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }

                if let safeData = data {
                    if let safeRecipeList = self.parseJSON(safeData){
                        
                        self.delegate?.didUpdateRecipeList(self, recipeList: safeRecipeList)
                    }
                }
            }

            //start the task
            task.resume()
        }
    }
    
    func parseJSON(_ recipeData: Data)-> [RecipeModel]?{
        let decoder = JSONDecoder()
        do{
            let decodedData = try decoder.decode([RecipeElement].self, from: recipeData)
            var recipeList: [RecipeModel] = []
            
            for r in decodedData{
                if !r.image.isEmpty {
                    let imageUrl = URL(string: r.image)!
                    let imageData = try! Data(contentsOf: imageUrl)
                    let recipe = RecipeModel(id: r.id, name: r.title, image: imageData, imageType: r.imageType)
                    recipeList.append(recipe)
                }
                else{
                    let recipe = RecipeModel(id: r.id, name: r.title, image: nil, imageType: nil)
                    recipeList.append(recipe)
                }
                
            }
            
            return recipeList

        } catch{
            self.delegate?.didFailWithError(error: error)
            return nil
        }
    }
    
}
