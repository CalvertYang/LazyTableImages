//
//  ParseOperation.swift
//  LazyTableImages
//
//  Created by Calvert Yang on 11/12/15.
//  Copyright © 2015 Calvert. All rights reserved.
//

import Foundation

// string contants found in the RSS feed
let idStr = "id"
let nameStr = "im:name"
let imageStr = "im:image"
let artistStr = "im:artist"
let entryStr = "entry"

class ParseOperation: NSOperation, NSXMLParserDelegate {

    // A block to call when an error is encountered during parsing.
    var errorHandler: (NSError -> Void)?

    // NSArray containing AppRecord instances for each entry parsed
    // from the input data.
    // Only meaningful after the operation has completed.
    // Redeclare appRecordList so we can modify it within this class
    private(set) var appRecordList: NSArray?

    private var dataToParse: NSData?
    private var workingArray: NSMutableArray?
    private var workingEntry: AppRecord?  // the current app record or XML entry being parsed
    private var workingPropertyString: NSMutableString?
    private var elementsToParse: NSArray
    private var storingCharacterData: Bool = false

    // MARK: -

    // -------------------------------------------------------------------------------
    //	initWithData:
    // -------------------------------------------------------------------------------
    init(data: NSData) {
        self.dataToParse = data
        self.elementsToParse = [idStr, nameStr, imageStr, artistStr]
    }

    // -------------------------------------------------------------------------------
    //	main
    //  Entry point for the operation.
    //  Given data to parse, use NSXMLParser and process all the top paid apps.
    // -------------------------------------------------------------------------------
    override func main() {
        // The default implemetation of the -start method sets up an autorelease pool
        // just before invoking -main however it does NOT setup an excption handler
        // before invoking -main.  If an exception is thrown here, the app will be
        // terminated.

        self.workingArray = NSMutableArray()
        self.workingPropertyString = NSMutableString()

        // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
        // desirable because it gives less control over the network, particularly in responding to
        // connection errors.
        //
        let parser = NSXMLParser(data: self.dataToParse!)
        parser.delegate = self
        parser.parse()

        if (!self.cancelled) {
            // Set appRecordList to the result of our parsing
            self.appRecordList = self.workingArray
        }

        self.workingArray = nil
        self.workingPropertyString = nil
        self.dataToParse = nil
    }


    //MARK: - RSS processing

    // -------------------------------------------------------------------------------
    //	parser:didStartElement:namespaceURI:qualifiedName:attributes:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        // entry: { id (link), im:name (app name), im:image (variable height) }
        //
        if (elementName == entryStr) {
            self.workingEntry = AppRecord()
        }
        self.storingCharacterData = self.elementsToParse.containsObject(elementName)
    }

    // -------------------------------------------------------------------------------
    //	parser:didEndElement:namespaceURI:qualifiedName:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (self.workingEntry != nil) {
            if (self.storingCharacterData) {
                let trimmedString = self.workingPropertyString?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                self.workingPropertyString = ""
                if (elementName == idStr) {
                    self.workingEntry!.appURLString = trimmedString
                } else if (elementName == nameStr) {
                    self.workingEntry!.appName = trimmedString
                } else if (elementName == imageStr) {
                    self.workingEntry!.imageURLString = trimmedString
                } else if (elementName == artistStr) {
                    self.workingEntry!.artist = trimmedString
                }
            } else if (elementName == entryStr) {
                self.workingArray?.addObject(self.workingEntry!)
                self.workingEntry = nil
            }
        }
    }

    // -------------------------------------------------------------------------------
    //	parser:foundCharacters:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if (self.storingCharacterData) {
            self.workingPropertyString?.appendString(string)
        }
    }

    // -------------------------------------------------------------------------------
    //	parser:parseErrorOccurred:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        self.errorHandler?(parseError)
    }

}
