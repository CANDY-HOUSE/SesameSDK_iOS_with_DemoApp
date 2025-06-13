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

extension IRDeviceType {
    static var deviceTypes: (fileName: String, attName: String) {
        (fileName: "strings", attName: "strs_device")
    }
    
    static func modelsMappingType(_ type: Int) -> (fileName: String, attName: String, icon: String) {
        switch type {
        case IRDeviceType.DEVICE_REMOTE_CUSTOM:    return (fileName: "", attName: "", icon: "DIY")
        case IRDeviceType.DEVICE_REMOTE_AIR:       return (fileName: "strings_air_type", attName: "strs_air_type", icon: "air_conditioner")
        case IRDeviceType.DEVICE_REMOTE_HW:        return (fileName: "strings_hw_type", attName: "strs_hw_type", icon: "water_heater")
        case IRDeviceType.DEVICE_REMOTE_AP:        return (fileName: "strings_ap_type", attName: "strs_ap_type", icon: "air_purifier")
        case IRDeviceType.DEVICE_REMOTE_TV:        return (fileName: "strings_tv_type", attName: "strs_tv_type", icon: "tv")
        case IRDeviceType.DEVICE_REMOTE_IPTV:      return (fileName: "strings_iptv_type", attName: "strs_iptv_type", icon: "iptv")
        case IRDeviceType.DEVICE_REMOTE_STB:       return (fileName: "strings_stb_type", attName: "strs_stb_type", icon: "stb")
        case IRDeviceType.DEVICE_REMOTE_DVD:       return (fileName: "strings_dvd_type", attName: "strs_dvd_type", icon: "dvd_player")
        case IRDeviceType.DEVICE_REMOTE_FANS:      return (fileName: "strings_fans_type", attName: "strs_fans_type", icon: "fan")
        case IRDeviceType.DEVICE_REMOTE_PJT:       return (fileName: "strings_pjt_type", attName: "strs_pjt_type", icon: "projector")
        case IRDeviceType.DEVICE_REMOTE_LIGHT:     return (fileName: "strings_light_type", attName: "strs_light_type", icon: "light")
        case IRDeviceType.DEVICE_REMOTE_DC:        return (fileName: "strings_dc_type", attName: "strs_dc_type", icon: "camera")
        case IRDeviceType.DEVICE_REMOTE_AUDIO:     return (fileName: "strings_audio_type", attName: "strs_audio_type", icon: "soundbox")
        case IRDeviceType.DEVICE_REMOTE_ROBOT:     return (fileName: "strings_robot_type", attName: "strs_robot_type", icon: "cleanner")
        default:
                                                   return (fileName: "", attName: "", icon: "")
        }
    }
}


