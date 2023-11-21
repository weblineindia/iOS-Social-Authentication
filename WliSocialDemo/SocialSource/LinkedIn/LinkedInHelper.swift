//
//  LinkedInHelper.swift
//  WliLinkedInDemo
//
//  Created by wli on 21/07/23.
//

import Foundation


// MARK: - LinkedInProfileModel

struct UserResponse: Codable {
    let firstName: FirstName
    let lastName: LastName
    let id: String
    
}

struct FirstName: Codable {
    let localized: LocalizedValue
    let preferredLocale: PreferredLocale
}

struct LastName: Codable {
    let localized: LocalizedValue
    let preferredLocale: PreferredLocale
}

struct LocalizedValue: Codable {
    let en_US: String
    
    enum CodingKeys: String, CodingKey {
        case en_US = "en_US"
    }
}

struct PreferredLocale: Codable {
    let country: String
    let language: String
}







struct LinkedInProfileModel: Codable {
    let firstName, lastName: StName
    let profilePicture: ProfilePicture
    let id: String
}

// MARK: - StName
struct StName: Codable {
    let localized: LILocalized
}

// MARK: - Localized
struct LILocalized: Codable {
    let enUS: String
    
    enum CodingKeys: String, CodingKey {
        case enUS = "en_US"
    }
}

// MARK: - ProfilePicture
struct ProfilePicture: Codable {
    let displayImage: DisplayImage
    
    enum CodingKeys: String, CodingKey {
        case displayImage = "displayImage~"
    }
}

// MARK: - DisplayImage
struct DisplayImage: Codable {
    let elements: [ProfilePicElement]
}

// MARK: - Element
struct ProfilePicElement: Codable {
    let identifiers: [ProfilePicIdentifier]
}

// MARK: - Identifier
struct ProfilePicIdentifier: Codable {
    let identifier: String
}



// MARK: - LinkedInEmailModel
struct LinkedInEmailModel: Codable {
    let elements: [Element]
}

// MARK: - Element
struct Element: Codable {
    let elementHandle: Handle
    let handle: String
    
    enum CodingKeys: String, CodingKey {
        case elementHandle = "handle~"
        case handle
    }
}

// MARK: - Handle
struct Handle: Codable {
    let emailAddress: String
}


