//
//  ComplicationController.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/7/1.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        var returnTemplate: CLKComplicationTemplate? = nil
        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            if let image = UIImage(named: "Complication/Modular") {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            returnTemplate = template
            break
        case .modularLarge:
            break
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallRingImage()
            if let image = UIImage(named: "Complication/Utilitarian") {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            returnTemplate = template
            break
        case .utilitarianLarge:
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "UtilLargeFlat", shortText: "TEMP", accessibilityLabel: "Sesame")
            if let image = UIImage(named: "Complication/Modular") {

                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            returnTemplate = template
            break
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!)
            returnTemplate = template
            break
        case .extraLarge:
            break
        case .graphicCorner:
            let template = CLKComplicationTemplateGraphicCornerStackText()
            template.innerTextProvider = CLKTextProvider(format: "Sesame")
            template.outerTextProvider = CLKTextProvider(format: "Sesame")
            returnTemplate = template
            break
        case .graphicBezel:
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            let circularImg = CLKComplicationTemplateGraphicCircularImage()
            if let image = UIImage(named: "Complication/Graphic Bezel") {
                circularImg.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            }
            let text = CLKTextProvider(format: "Sesame")
            template.circularTemplate = circularImg
            template.textProvider = text
            returnTemplate = template
            break
        case .graphicCircular:
            let template = CLKComplicationTemplateGraphicCircularImage()
            if let image = UIImage(named: "Complication/Graphic Circular") {
                template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            }
            returnTemplate = template
        case .graphicRectangular:
            break
        case .utilitarianSmallFlat:
            break
        @unknown default:
            break
        }
        
        handler(returnTemplate)
    }
    
}
