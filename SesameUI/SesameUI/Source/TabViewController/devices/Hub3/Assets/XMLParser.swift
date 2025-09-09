//
//  XMLParser.swift
//  SesameUI
//
//  Created by eddy on 2024/1/25.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

struct ContentModel {
    let code: String
    let plainText: String
    
    init(code: String, planText: String) {
        self.code = code
        self.plainText = planText
    }
}

class XMLParseHandler: NSObject, XMLParserDelegate {
    private var elements: [ContentModel] = []
    private var currentElement = ""
    private var parentElement = ""
    private var foundElement = false
    private var elementNameToFind = ""
    private var currentCode: String?
    private var currentPlanText = ""
    private var parser: XMLParser!

    func parseXML(data: Data, elementName: String) -> [ContentModel]? {
        elementNameToFind = elementName
        parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() {
            return elements
        }
        return nil
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if attributeDict["name"] == elementNameToFind {
            parentElement = elementName
            foundElement = true
        }
        if foundElement && elementName == "item" {
            currentCode = attributeDict["code"]
            currentPlanText = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if foundElement && currentElement == "item" {
            currentPlanText += string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if foundElement && elementName == "item" {
            let contentModel = ContentModel(code: currentCode ?? "", planText: currentPlanText)
            elements.append(contentModel)
            currentCode = nil
        }
        if foundElement && parentElement == elementName {
            foundElement = false
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parse error: \(parseError.localizedDescription)")
    }
}

extension XMLParseHandler {
    static func fetchXMLContent(fileName: String, eleAttrName: String, completion: @escaping ([ContentModel]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard !fileName.isEmpty, !eleAttrName.isEmpty else {
                executeOnMainThread {
                    completion([])
                }
                return
            }
            if let filePath = Bundle.main.path(forResource: fileName, ofType: "xml"),
               let xmlData = FileManager.default.contents(atPath: filePath) {
                if let result = XMLParseHandler().parseXML(data: xmlData, elementName: eleAttrName) {
                    executeOnMainThread {
                        completion(result)
                    }
                } else {
                    executeOnMainThread {
                        completion([])
                    }
                }
            }
        }
    }
}

extension IRType {
    static var deviceTypes: (fileName: String, attName: String) {
        (fileName: "strings", attName: "strs_device")
    }
    
    static func modelsMappingType(_ type: Int) -> (attName: String, icon: String) {
        switch type {
        case IRType.DEVICE_REMOTE_CUSTOM:    return (attName: "", icon: "DIY")
        case IRType.DEVICE_REMOTE_AIR:       return (attName: "strs_air_type", icon: "air_conditioner")
        case IRType.DEVICE_REMOTE_HW:        return (attName: "strs_hw_type", icon: "water_heater")
        case IRType.DEVICE_REMOTE_AP:        return (attName: "strs_ap_type", icon: "air_purifier")
        case IRType.DEVICE_REMOTE_TV:        return (attName: "strs_tv_type", icon: "tv")
        case IRType.DEVICE_REMOTE_IPTV:      return (attName: "strs_iptv_type", icon: "iptv")
        case IRType.DEVICE_REMOTE_STB:       return (attName: "strs_stb_type", icon: "stb")
        case IRType.DEVICE_REMOTE_DVD:       return (attName: "strs_dvd_type", icon: "dvd_player")
        case IRType.DEVICE_REMOTE_FANS:      return (attName: "strs_fans_type", icon: "fan")
        case IRType.DEVICE_REMOTE_PJT:       return (attName: "strs_pjt_type", icon: "projector")
        case IRType.DEVICE_REMOTE_LIGHT:     return (attName: "strs_light_type", icon: "light")
        case IRType.DEVICE_REMOTE_DC:        return (attName: "strs_dc_type", icon: "camera")
        case IRType.DEVICE_REMOTE_AUDIO:     return (attName: "strs_audio_type", icon: "soundbox")
        case IRType.DEVICE_REMOTE_ROBOT:     return (attName: "strs_robot_type", icon: "cleanner")
        default:
                                             return (attName: "", icon: "")
        }
    }
}


