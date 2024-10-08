//
//  FavoritesViewModel.swift
//  DragonBallSwift
//
//  Created by Jacob Aguilar on 30-07-24.
//

import Foundation

@Observable
class FavoritesViewModel {
    private let favoriteCharactersDataBaseService = FavoriteCharacterDataBaseService()
    private let charactersServer: CharactersService = CharactersService()
    var favoriteCharactersIDs: [FavoriteCharacter] = []
    var favoriteCharacters: [CharactersModel] = [] //Modelo con todos los datos de los personajes favoritos
    var isLoading: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""
    
    /// Agrega un personaje a la lista de favoritos (en la memoria y en Firestore).
    ///
    /// Esta función realiza las siguientes acciones:
    /// 1. Crea un objeto `FavoriteCharacter` con el ID del personaje proporcionado.
    /// 2. Agrega este objeto a la lista local `favoriteCharacters`.
    /// 3. Intenta guardar el personaje en la base de datos de Firestore a través del servicio `favoriteCharactersDataBaseService`.
    /// 4. Actualiza la lista de favoritos llamando a `getFavoriteCharacters()`.
    /// 5. En caso de error, establece las variables `showError` y `errorMessage` para mostrar un mensaje al usuario.
    ///
    /// - Parameter characterID: El ID del personaje que se agregará a favoritos.
    func addToFavorites(characterID: Int) async {
        do {
            let character = FavoriteCharacter(characterID: characterID)
            favoriteCharactersIDs.append(character)
            try await favoriteCharactersDataBaseService.addToFavorites(character: character)
            await getFavoriteCharactersIDs()
        } catch {
            showError = true
            errorMessage = "Error al agregar a favoritos"
        }
    }
    
    
    /// Obtiene la lista de personajes favoritos desde la base de datos de Firestore.
    ///
    /// Esta función actualiza la lista local `favoriteCharacters` con los datos obtenidos desde el servicio de Firestore `favoriteCharactersDataBaseService`.
    func getFavoriteCharactersIDs() async {
        do {
            favoriteCharactersIDs = try await favoriteCharactersDataBaseService.getFavorites()
        } catch {
            showError = true
            errorMessage = "Error al obtener personajes favoritos"
        }
    }
    
    
    @MainActor
    func getFavoriteCharactersModels() async {
        do {
            let favoriteCharactersFromDB = try await charactersServer.getCharacters("dragonball")
            let favoriteCharactersFromDBZ = try await charactersServer.getCharacters("dragonballz")
            let favoriteCharactersFromDBGT = try await charactersServer.getCharacters("dragonballgt")
            let favoriteCharactersFromDBD = try await charactersServer.getCharacters("dragons")
            
            //Creación de un Set (Recordar que los Set no permiten duplicidad de elementos y son más rápidos a la hora de iterar elementos)
            let favoriteCharacterIDsSet = Set(favoriteCharactersIDs.map { $0.characterID })
            
            let allCharacters = favoriteCharactersFromDB + favoriteCharactersFromDBZ + favoriteCharactersFromDBGT + favoriteCharactersFromDBD
            
            favoriteCharacters = allCharacters.filter { favoriteCharacterIDsSet.contains(Int( $0.id)) }
        } catch {
            
        }
    }
    
//    @MainActor
//    func getFavoriteCharactersModels(_ charactersModels: [CharactersModel]){
//        //Creación de un Set (Recordar que los Set no permiten duplicidad de elementos y son más rápidos a la hora de iterar elementos)
//        let favoriteCharacterIDsSet = Set(favoriteCharactersIDs.map { $0.characterID })
//        let allCharacters = charactersModels
//        favoriteCharacters = allCharacters.filter{ favoriteCharacterIDsSet.contains(Int($0.id))}
//    }
    
    /// Verifica si un personaje está en la lista de favoritos.
    ///
    /// - Parameter characterID: El ID del personaje a buscar.
    /// - Returns: `true` si el personaje está en favoritos, `false` en caso contrario.
    func checkIsFavorite(characterID: Int) async -> Bool {
        return favoriteCharactersIDs.contains(where: { $0.characterID == characterID })
    }
    
    
    /// Elimina un personaje de la lista de favoritos (De la memoria y de Firestore).
    ///
    /// Esta función realiza las siguientes acciones:
    /// 1. Elimina el personaje de la lista local `favoriteCharacters`.
    /// 2. Intenta eliminar el personaje de la base de datos.
    /// 3. Actualiza la lista de favoritos.
    /// 4. Devuelve `true` si la eliminación fue exitosa, `false` en caso contrario.
    ///
    /// - Parameter characterID: El ID del personaje a eliminar.
    /// - Returns: `true` si la eliminación fue exitosa, `false` si hubo un error.
    func removeFromFavorites(characterID: Int) async -> Bool {
        do {
            favoriteCharacters.removeAll(where: { $0.id == characterID })
            favoriteCharactersIDs.removeAll(where: { $0.characterID == characterID })
            try await favoriteCharactersDataBaseService.deleteFavoriteCharacter(characterID: characterID)
            await getFavoriteCharactersIDs()
            return true
        } catch {
            showError = true
            errorMessage = "No se pudo eliminar el personaje desde favoritos"
            return false
        }
    }
}
