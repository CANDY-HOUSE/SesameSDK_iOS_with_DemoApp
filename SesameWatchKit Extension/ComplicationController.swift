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
        handler(complication.family.currentTimelineEntry())
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
        handler(complication.family.localizableSampleTemplate())
    }
    
}

extension CLKComplicationFamily {
    private enum ComplicationIcon {
        static let utilitarian = "Complication/Utilitarian"
        static let graphicLargeRectangular = "Complication/Graphic Large Rectangular"
        static let graphicCircular = "Complication/Graphic Circular"
        static let graphicBezel = "Complication/Graphic Bezel"
        static let graphicCorner = "Complication/Graphic Corner"
        static let graphicExtraLarge = "Complication/Graphic Extra Large"
        static let circular = "Complication/Circular"
        static let modular = "Complication/Modular"
    }
    
    private enum Template {
        static let modular: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            if let image = UIImage(named: ComplicationIcon.modular) {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            return template
        }()
        
        static let modularLarge: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateModularLargeStandardBody()
            let headerText = CLKSimpleTextProvider(text: "Sesame")
            headerText.tintColor = .sesame2Green
            template.headerTextProvider = headerText
            let bodyText = CLKSimpleTextProvider(text: "Tap to open")
            template.body1TextProvider = bodyText
            return template
        }()
        
        static let utilitarianSmall: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateUtilitarianSmallRingImage()
            if let image = UIImage(named: ComplicationIcon.utilitarian) {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            return template
        }()
        
        static let utilitarianLarge: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "Sesame")
            if let image = UIImage(named: ComplicationIcon.utilitarian) {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            return template
        }()
        
        static let circularSmall: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            if let image = UIImage(named: ComplicationIcon.circular) {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            return template
        }()
        
        static let extraLarge: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateExtraLargeSimpleImage()
            if let image = UIImage(named: ComplicationIcon.graphicExtraLarge) {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            return template
        }()
        
        static let graphicCorner: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateGraphicCornerTextImage()
            template.textProvider = CLKTextProvider(format: "Sesame")
            if let image = UIImage(named: ComplicationIcon.graphicCorner) {
                template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            }
            return template
        }()
        
        static let graphicBezel: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateGraphicBezelCircularText()
            let circularImg = CLKComplicationTemplateGraphicCircularImage()
            if let image = UIImage(named: ComplicationIcon.graphicBezel) {
                circularImg.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            }
            let text = CLKTextProvider(format: "Sesame")
            template.circularTemplate = circularImg
            template.textProvider = text
            return template
        }()
        
        static let graphicCircular: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateGraphicCircularImage()
            if let image = UIImage(named: ComplicationIcon.graphicCircular) {
                template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
            }
            return template
        }()
        
        static let graphicRectangular: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateGraphicRectangularStandardBody()
            let headerText = CLKSimpleTextProvider(text: "Sesame")
            headerText.tintColor = .sesame2Green
            template.headerTextProvider = headerText
            template.body1TextProvider = CLKTextProvider(format: "Tap to open")
            return template
        }()
        
        static let utilitarianSmallFlat: CLKComplicationTemplate = {
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            if let image = UIImage(named: ComplicationIcon.utilitarian) {
                template.imageProvider = CLKImageProvider(onePieceImage: image)
            }
            template.textProvider = CLKTextProvider(format: "Sesame")
            return template
        }()
    }
    
    func localizableSampleTemplate() -> CLKComplicationTemplate? {
        var returnTemplate: CLKComplicationTemplate? = nil
        switch self {
        case .modularSmall:
            returnTemplate = Template.modular
        case .modularLarge:
            returnTemplate = Template.modularLarge
        case .utilitarianSmall:
            returnTemplate = Template.utilitarianSmall
        case .utilitarianLarge:
            returnTemplate = Template.utilitarianLarge
        case .circularSmall:
            returnTemplate = Template.circularSmall
        case .extraLarge:
            returnTemplate = Template.extraLarge
        case .graphicCorner:
            returnTemplate = Template.graphicCorner
        case .graphicBezel:
            returnTemplate = Template.graphicBezel
        case .graphicCircular:
            returnTemplate = Template.graphicCircular
        case .graphicRectangular:
            returnTemplate = Template.graphicRectangular
        case .utilitarianSmallFlat:
            returnTemplate = Template.utilitarianSmallFlat
        case .graphicExtraLarge:
            break
        @unknown default:
            break
        }
        return returnTemplate
    }
    
    func currentTimelineEntry() -> CLKComplicationTimelineEntry? {
        return CLKComplicationTimelineEntry(date: Date(),
                                            complicationTemplate: self.localizableSampleTemplate()!)
    }
}
