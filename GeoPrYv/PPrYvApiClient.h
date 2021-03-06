//
//  PPrYvApiClient.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 21.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

/**
 @discussion
 This class provides an easy way to upload events to the RESTful PrYv API using the well known AFNetworking library.
 You can find AFNetworking on github at this address https://github.com/AFNetworking/AFNetworking
 
 On PrYv, Events are sent as JSON Data parameters. Single event can have files attached to them.
 Events can be of differents types.
 See http://pryv.github.com/event-types.html
     http://pryv.github.com/standard-structure.html

 Each Application uses one streamId and can have multiple folders within this streamId
 You have only one streamIdId per application.

 Visit http://pryv.github.com/ for the complete documentation on the PrYv API
 
 */

#import <Foundation/Foundation.h>

@class PositionEvent;

@interface PPrYvApiClient : NSObject {
}

@property (copy, nonatomic) NSString * userId;
@property (copy, nonatomic) NSString * oAuthToken;
@property (copy, nonatomic) NSString * streamIdId;
@property (readonly, nonatomic) NSTimeInterval serverTimeInterval;


/**
 @discussion
 Allows you to access the Pryv Api Client singleton
 You must first set the userId, oAuthToken and streamIdId before
 Communicating with the API
 
 # method
 +[PPrYvApiClient startClientWithUserId:oAuthToken:streamIdId:successHandler:errorHandler]
 */
+ (PPrYvApiClient *)sharedClient;

 // ---------------------------------------------------------------------------------------------------------------------
 // @name Initiation of protocol
 // ---------------------------------------------------------------------------------------------------------------------

/**
 @discussion
 You need to call this method at least once prior to any action with the api. but you can call it as many time as you want.
 You can modify the client properties during the application lifetime by setting its properties directly.
 
 */
- (void)startClientWithUserId:(NSString *)userId
                   oAuthToken:(NSString *)token
                    streamIdId:(NSString *)streamIdId
               successHandler:(void (^)(NSTimeInterval serverTime))successHandler
                 errorHandler:(void(^)(NSError *error))errorHandler;


/**
 @discussion
 this method simply connect to the PrYv API to retrive the server time in the returned header
 This method will be called when you start the manager

    GET /

 */
- (void)synchronizeTimeWithSuccessHandler:(void(^)(NSTimeInterval serverTime))successHandler
                             errorHandler:(void(^)(NSError *error))errorHandler;


// ---------------------------------------------------------------------------------------------------------------------
// @name Event operations
// ---------------------------------------------------------------------------------------------------------------------

/**
 @discussion
 Send an position event with one or more attachments

    POST /{streamId-id}/events/

 @param event PositionEvent to send to Api

 @see PositionEvent
*/
- (void)sendEvent:(PositionEvent *)event completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;


/**
 @discussion
 Update the duration of event
        PUT /{streamId-id}/events/{event-id}

 @param event PositionEvent with duration and event-id set
 
 @see PositionEvent
 */
- (void)updateEvent:(PositionEvent *)event completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;


/**
 @discussion
 get events between two dates, pass nil to both @param startDate and @param endDate to get the last 24h 
 pass nil to @param streamId to get events from all folders in the current streamId Id

    GET /{streamId-id}/events/

 */
- (void)getEventsFromStartDate:(NSDate *)startDate
                     toEndDate:(NSDate *)endDate
                    instreamId:(NSString *)streamId
                successHandler:(void (^)(NSArray *positionEventList))successHandler
                  errorHandler:(void(^)(NSError *error))errorHandler;

// ---------------------------------------------------------------------------------------------------------------------
// @name Events of class note
// ---------------------------------------------------------------------------------------------------------------------


/**
 @discussion
 Send an event of class note:txt
 
 POST /{streamId-id}/events/
 
 @param event of type note:txt to send
 
 @see PositionEvent
 */
- (void)sendNoteEvent:(PositionEvent *)event
    completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;


// ---------------------------------------------------------------------------------------------------------------------
// @name Events of class picture
// ---------------------------------------------------------------------------------------------------------------------

/**
 @discussion
 Send an event of class picture:attached
 
 POST /{streamId-id}/events/
 
 @param event of type picture:attached. attachmentList shouold containg at least one EventAttachment
 
 @see PositionEvent
 @see EventAttachment
 */

- (void)sendPictureEvent:(PositionEvent *)event
       completionHandler:(void(^)(NSString *eventId, NSError *error))completionHandler;

// ---------------------------------------------------------------------------------------------------------------------
// @name Folder operations
// ---------------------------------------------------------------------------------------------------------------------


/**
 @discussion
 Get list of all folders

    GET /{streamId-id}/folders/

 @param successHandler A block object to be executed when the operation finishes successfully. This block has no return value and takes one argument NSArray of Folder objects

 */
- (void)getFoldersWithSuccessHandler:(void (^)(NSArray *folderList))successHandler
                        errorHandler:(void (^)(NSError *error))errorHandler;


/**
 @discussion
 Get list of folders for a streamId
 
    GET /{streamId-id}/folders/
 
 @param streamIdId of the streamId to get folders from
 
 */
- (void)getFoldersInstreamId:(NSString *)streamIdId
         withSuccessHandler:(void (^)(NSArray *folderList))successHandler
               errorHandler:(void (^)(NSError *error))errorHandler;

/**
 @discussion
 Create a new folder in the current streamId Id
 folders have one unique Id AND one unique name. Both must be unique

    POST /{streamId-id}/folders/

 */
- (void)createstreamId:(NSString *)streamId
              withName:(NSString *)folderName
        successHandler:(void (^)(NSString *createdstreamId, NSString *createdFolderName))successHandler
          errorHandler:(void (^)(NSError *error))errorHandler;


/**
 @discussion
 Rename an existing folder Id in the current streamId Id with a new name

    PUT /{streamId-id}/folders/{id}

 */
- (void)renamestreamId:(NSString *)streamId
     withNewFolderName:(NSString *)folderName
        successHandler:(void(^)(NSString *createdstreamId, NSString *newFolderName))successHandler
          errorHandler:(void(^)(NSError *error))errorHandler;

@end