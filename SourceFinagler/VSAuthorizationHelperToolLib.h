/*
	File:       VSAuthorizationHelperToolLib.h

    Contains:   Interface to reusable code for privileged helper tools.

    Written by: DTS

    Copyright:  Copyright (c) 2007 Apple Inc. All Rights Reserved.

    
*/

#ifndef _VSAuthorizationHelperToolLib_H
#define _VSAuthorizationHelperToolLib_H

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <asl.h>

#ifdef __cplusplus
extern "C" {
#endif

/////////////////////////////////////////////////////////////////

/*
    This header has extensive HeaderDoc comments.  To see these comments in a more 
    felicitous form, you can generate HTML from the HeaderDoc comments using the 
    following command:
    
    $ headerdoc2html VSAuthorizationHelperToolLib.h
    $ open VSAuthorizationHelperToolLib/index.html
*/

/*!
    @header         VSAuthorizationHelperToolLib
    
    @abstract       Reusable library for creating helper tools that perform privileged 
                    operations on behalf of your application.

    @discussion     VSAuthorizationHelperToolLib allows you to perform privileged operations 
                    in a helper tool. In this model, your application runs with standard 
                    privileges and, when it needs to do a privileged operation, it makes a 
                    request to the helper tool.  The helper tool uses Authorization Services 
                    to ensure that the user is authorized to perform that operation.
                    
                    VSAuthorizationHelperToolLib takes care of all of the mechanics of 
                    installing the helper tool and communicating with it.  Specifically, it 
                    has routines that your application can call to:
                    
                     1. send requests to a helper tool (VSExecuteRequestInHelperTool) 
                      
                     2. install the helper tool if it's not installed, or fix an installation if 
                        it's broken (VSDiagnoseFailure and VSFixFailure)
                      
                    VSAuthorizationHelperToolLib also helps you implement the helper tool.  
					Specifically, you call the routine VSHelperToolMain in the main entry 
					point for your helper tool, passing it an array of command callbacks (of 
                    type VSCommandProc).  VSHelperToolMain will take care of all the details 
                    of communication with the application and only call your callback to 
                    execute the actual command.
                    
                    A command consists of request and response CFDictionaries (or, equivalently, 
                    NSDictionaries).  VSAuthorizationHelperToolLib defines three special keys for 
                    these dictionaries:
                    
                     1. kVSCommandKey -- In the request dictionary, this is the name of the 
                        command. Its value is a string that uniquely identifies the command within 
                        your program.
                    
                     2. kVSErrorKey -- In the response dictionary, this is the error result for 
                        the request. Its value is an OSStatus-style error code.
                    
                     3. kVSDescriptorArrayKey -- In the response dictionary, if present, this is 
                        an array of file descriptors being returned from the helper tool.

                    You can use any other key to represent addition parameters (or return values) 
                    for the command.  The only constraints that VSAuthorizationHelperToolLib applies 
                    to these extra parameters is that they must be serialisable as a CFPropertyList.
                    
                    VSAuthorizationHelperToolLib requires that you tell it about the list of commands 
                    that you support.  Each command is represented by a command specification 
                    (VSCommandSpec).  The command specification includes the following information:
                    
                     1. The name of the command.  This is the same as the kVSCommandKey value in 
                        the request dictionary.
                      
                     2. The authorization right associated with the command.  VSAuthorizationHelperToolLib 
						uses this to ensure that the user is authorized to use the command before 
                        it calls your command callback in the privileged helper tool.
                        
                     3. Information to create the command's authorization right specification in the 
                        policy database.  The is used by the VSSetDefaultRules function.
                    
                    Finally, VSAuthorizationHelperToolLib includes a number of utilities routines to help 
                    wrangle error codes (VSErrnoToOSStatus, VSOSStatusToErrno, and VSGetErrorFromResponse) 
                    and file descriptors (VSCloseDescriptorArray).
*/

/////////////////////////////////////////////////////////////////
#pragma mark ***** Command Description

/*!
    @struct         VSCommandSpec
    
    @abstract       Describes a privileged operation to VSAuthorizationHelperToolLib.
    
    @discussion     Both the application and the tool must tell VSAuthorizationHelperToolLib about 
                    the operations (that is, commands) that they support.  They do this by passing 
                    in an array of VSCommandSpec structures.  Each element describes one command.  
                    The array is terminated by a command whose commandName field is NULL.
                    
                    In general the application and tool should use the same array definition.  
                    However, there are cases where these might be out of sync.  For example, if you 
                    have an older version of the application talking to a newer version of the tool, 
                    the tool might know about more commands than the application (and thus provide a 
                    longer array), and that's OK.
                    
    @field commandName
                    A identifier for this command.  This can be any string that is unique within 
                    the context of your programs.  A NULL value in this field terminates the array.
					
					The length of the command name must not be greater than 1024 UTF-16 values.

    @field rightName
                    This is the name of the authorization right associated with the 
                    command.  This can be NULL if you don't want any right associated with the 
                    command.  If it's not NULL, VSAuthorizationHelperToolLib will acquire that right 
                    before allowing the command to execute.
    
    @field rightDefaultRule
                    This is the name of an authorization rule that should be used in 
                    the default right specification for the right.  To see a full list of these rules, 
                    look at the "rules" dictionary within the policy database (currently 
					"/etc/authorization").  Common values include "default" (which requires that the user 
					hold credentials that authenticate them as an admin user) and "allow" (which will let 
					anyone acquire the right).
                    
                    This must be NULL if (and only if) rightName is NULL.

    @field rightDescriptionKey
                    This is a key used to form a custom prompt for the right.  The value of this 
                    string should be a key into a .strings file whose name you supply to 
                    VSSetDefaultRules.  When VSAuthorizationHelperToolLib creates the right specification, 
                    it uses this key to get all of the localised prompt strings for the right.

                    This must be NULL if rightName is NULL.  Otherwise, this may be NULL if you 
                    don't want a custom prompt for your right.

    @field userData
                    This field is is for the benefit of the client; VSAuthorizationHelperToolLib 
                    does not use it in any way.
*/

struct VSCommandSpec {
	const char		*commandName;
	const char		*rightName;
	const char		*rightDefaultRule;
	const char		*rightDescriptionKey;
    const void		*userData;
};
typedef struct VSCommandSpec VSCommandSpec;

/////////////////////////////////////////////////////////////////
#pragma mark ***** Request/Response Keys

// Standard keys for the request dictionary

/*!
    @define         kVSCommandKey
    
    @abstract       Key for the command string within the request dictionary.
    
    @discussion     Within a request, this key must reference a string that is the name of the 
                    command to execute.  This must match one of the commands in the 
                    VSCommandSpec array.
					
					The length of a command name must not be greater than 1024 UTF-16 values.
*/

#define kVSCommandKey      "com.markdouma.SourceFinagler.command"			// CFString

// Standard keys for the response dictionary

/*!
    @define         kVSErrorKey
    
    @abstract       Key for the error result within the response dictionary.
    
    @discussion     Within a response, this key must reference a number that is the error result 
                    for the response, interpreted as an OSStatus.
*/

#define kVSErrorKey        "com.markdouma.SourceFinagler.error"				// CFNumber

/*!
    @define         kVSDescriptorArrayKey
    
    @abstract       Key for a file descriptor array within the response dictionary.
    
    @discussion     Within a response, this key, if present, must reference an array 
					of numbers, which are the file descriptors being returned with 
					the response.  The numbers are interpreted as ints.
*/

#define kVSDescriptorArrayKey "com.markdouma.SourceFinagler.descriptors"	// CFArray of CFNumber

/////////////////////////////////////////////////////////////////
#pragma mark ***** Helper Tool Routines

/*!
    @functiongroup  Helper Tool Routines
*/

/*!
    @typedef        VSCommandProc
    
    @abstract       Command processing callback.
    
    @discussion     When your helper tool calls VSHelperToolMain, it passes in a pointer to an 
                    array of callback functions of this type.  When VSHelperToolMain receives a 
                    valid command, it calls one of these function so that your program-specific 
                    code can process the request.  VSAuthorization guarantees that the effective, save and 
                    real user IDs (EUID, SUID, RUID) will all be zero at this point (that is, 
                    you're "running as root").
                    
                    By the time this callback is called, VSHelperToolMain has already verified that 
                    this is a known command.  It also acquires the authorization right associated 
                    with the command, if any.  However, it does nothing to validate the other 
                    parameters in the request.  These parameters come from a non-privileged source 
                    and you should verify them carefully.
                    
                    Your implementation should get any input parameters from the request and place 
                    any output parameters in the response.  It can also put an array of file 
                    descriptors into the response using the kVSDescriptorArrayKey key.
                    
                    If an error occurs, you should just return an appropriate error code.  
                    VSHelperToolMain will ensure that this gets placed in the response.
                    
                    You should attempt to fail before adding any file descriptors to the response, 
                    or remove them once you know that you're going to fail.  If you put file 
                    descriptors into the response and then return an error, those descriptors will 
                    still be passed back to the client.  It's likely the client isn't expecting this.

                    Calls to this function will be serialised; that is, once your callback is 
                    running, VSHelperToolMain won't call you again until you return.  Your callback 
                    should avoid blocking for long periods of time.  If you block for too long, the 
                    VSAuthorization watchdog will kill the entire helper tool process.
                    
                    This callback runs in a daemon context; you must avoid doing things that require the 
                    user's context.  For example, launching a GUI application would be bad.  See 
                    Technote 2083 "Daemons and Agents" for more information about execution contexts.
                    
    @param auth     This is a reference to the authorization instance associated with the original 
                    application that made the request.
                    
                    This will never be NULL.

    @param userData This is the value from the userData field of the corresponding entry in the 
                    VSCommandSpec array that you passed to VSHelperToolMain.

    @param request  This dictionary contains the request.  It will have, at a bare minimum, a 
                    kVSCommandKey item whose value matches one of the commands in the 
                    VSCommandSpec array you passed to VSHelperToolMain.  It may also have 
					other, command-specific parameters.

                    This will never be NULL.

    @param response This is a dictionary into which you can place the response.  It will start out 
                    empty, and you can add any results you please to it.

                    If you need to return file descriptors, place them in an array and place that 
                    array in the response using the kVSDescriptorArrayKey key.
                    
                    There's no need to set the error result in the response.  VSHelperToolMain will 
                    do that for you.  However, if you do set a value for the kVSErrorKey key, 
                    that value will take precedence; in this case, the function result is ignored.

                    This will never be NULL.

    @param asl      A reference to the ASL client handle for logging.

                    This may be NULL.  However, ASL handles a NULL input, so you don't need to 
                    conditionalise your code.

    @param aslMsg   A reference to a ASL message template for logging.

                    This may be NULL.  However, ASL handles a NULL input, so you don't need to 
                    conditionalise your code.
*/

typedef OSStatus (*VSCommandProc)(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
);

/*!
    @function       VSHelperToolMain
    
    @abstract       Entry point for a privileged helper tool.
    
    @discussion     You should call this function from the main function of your helper tool.  It takes 
                    care of all of the details of receiving and processing commands.  It will call you 
                    back (via one of the commandProcs callbacks) when a valid request arrives.
                    
                    This function assumes acts like a replacement for main.  Thus, it assumes that 
                    it owns various process-wide resources (like SIGALRM and the disposition of 
                    SIGPIPE).  You should not use those resources, either in your main function or 
                    in your callback function.  Also, you should not call this function on a thread, 
					or start any other threads in the process.  Finally, this function has a habit of 
					exiting the entire process if something goes wrong.  You should not expect the 
					function to always return.
                    
                    This function does not clean up after itself.  When this function returns, you 
                    are expected to exit.  If the function result is noErr, the command processing 
                    loop quit in an expected manner (typically because of an idle timeout).  Otherwise 
                    it quit because of an error.

    @param commands An array that describes the commands that you implement, and their associated 
                    rights.  The array is terminated by a command with a NULL name.  There must be 
                    at least one valid command.

    @param commandProcs
                    An array of callback routines that are called when a valid request arrives.  The 
                    array is expected to perform the operation associated with the corresponding 
                    command and set up the response values, if any.  The array is terminated by a 
                    NULL pointer.
                    
                    IMPORTANT: The array must have exactly the same number of entries as the 
                    commands array.
					
	@result			An integer representing EXIT_SUCCESS or EXIT_FAILURE.
*/

extern int VSHelperToolMain(
	const VSCommandSpec		commands[], 
	const VSCommandProc		commandProcs[]
);

/////////////////////////////////////////////////////////////////
#pragma mark ***** Application Routines

/*!
    @functiongroup  Application Routines
*/

/*!
    @function       VSSetDefaultRules
    
    @abstract       Creates default right specifications in the policy database.
    
    @discussion     This routine ensures that the policy database (currently 
                    "/etc/authorization") contains right specifications for all of the rights 
                    that you use (as specified by the commands array).  This has two important 
                    consequences:

                     1. It makes the rights that you use visible to the system administrator.  
                        All they have to do is run your program once and they can see your default 
                        right specifications in the policy database. 

                     2. It means that, when the privileged helper tool tries to acquire the right, 
                        it will use your specification of the right (as modified by the system 
                        administrator) rather than the default right specification. 

                    You must call this function before calling VSExecuteRequestInHelperTool.  
                    Typically you would call it at application startup time, or lazily, immediately 
                    before calling VSExecuteRequestInHelperTool.

    @param auth     A reference to your program's authorization instance; you typically get this 
                    by calling AuthorizationCreate.
    
                    This must not be NULL.

    @param commands An array that describes the commands that you implement, and their associated 
                    rights.  There must be at least one valid command.

    @param bundleID The bundle identifier for your program.

                    This must not be NULL.

    @param descriptionStringTableName
                    The name of the .strings file from which to fetch the localised custom 
                    prompts for the rights in the commands array (if any).  A NULL value is 
                    equivalent to passing "Localizable" (that is, it gets the prompts from 
                    "Localizable.strings").
                    
                    For example, imagine you have a command for which you require a custom prompt.  
                    You should put the custom prompt in a .strings file, let's call it 
                    "AuthPrompts.strings".  You should then pass "AuthPrompts" to this parameter 
                    and put the key that gets the prompt into the rightDescriptionKey of the command.
*/

extern void VSSetDefaultRules(
	AuthorizationRef			auth,
	const VSCommandSpec			commands[],
	CFStringRef					bundleID,
	CFStringRef					descriptionStringTableName
);

/*!
    @function       VSExecuteRequestInHelperTool
    
    @abstract       Executes a request in the privileged helper tool, returning the response.
    
    @discussion     This routine synchronously executes a request in the privileged helper tool and 
                    returns the response.
    
                    If the function returns an error, the IPC between your application and the helper tool 
                    failed.  Unfortunately it's not possible to tell whether this failure occurred while 
                    sending the request or receiving the response, thus it's not possible to know whether 
                    the privileged operation was done or not. 

                    If the functions returns no error, the IPC between your application and the helper tool 
                    was successful.  However, the command may still have failed.  You must get the error 
                    value from the response (typically using VSGetErrorFromResponse) to see if the 
                    command succeeded or not.
                    
                    On success the response dictionary may contain a value for the kVSDescriptorArrayKey key.  
                    If so, that will be a non-empty CFArray of CFNumbers, each of which can be accessed as an int.  
                    Each value is a descriptor that is being returned to you from the helper tool.  You are 
					responsible for closing these descriptors when you're done with them. 

    @param auth     A reference to your program's authorization instance; you typically get this 
                    by calling AuthorizationCreate.
    
                    This must not be NULL.

    @param commands An array that describes the commands that you implement, and their associated 
                    rights.  There must be at least one valid command.

    @param bundleID The bundle identifier for your program.

                    This must not be NULL.

    @param request  A dictionary describing the requested operation.  This must, at least, contain 
                    a string value for the kVSCommandKey.  Furthermore, this string must match 
                    one of the commands in the array.
                    
                    The dictionary may also contain other values.  These are passed to the helper 
                    tool unintepreted.  All values must be serialisable using the CFPropertyList 
                    API.

                    This must not be NULL.

    @param response This must not be NULL.  On entry, *response must be NULL.  On success, *response 
                    will not be NULL.  On error, *response will be NULL.
                    
                    On success, you are responsible for disposing of *response.  You are also 
                    responsible for closing any descriptors returned in the response.
	
	@result			An OSStatus code (see VSErrnoToOSStatus and VSOSStatusToErrno).
*/

extern OSStatus VSExecuteRequestInHelperTool(
	AuthorizationRef			auth,
	const VSCommandSpec			commands[],
	CFStringRef					bundleID,
	CFDictionaryRef				request,
	CFDictionaryRef *			response
);

/*!
    @enum           VSFailCode
    
    @abstract       Indicates why a request failed.
    
    @discussion     If VSExecuteRequestInHelperTool fails with an error (indicating 
					an IPC failure), you can call VSDiagnoseFailure to determine what 
					went wrong.  VSDiagnoseFailure will return the value of this 
					type that best describes the failure.

    @constant kVSFailUnknown
                    Indicates that VSDiagnoseFailure could not accurately determine the cause of the 
                    failure.

    @constant kVSFailDisabled
                    The request failed because the helper tool is installed but disabled.

    @constant kVSFailPartiallyInstalled
                    The request failed because the helper tool is only partially installed.

    @constant kVSFailNotInstalled 
                    The request failed because the helper tool is not installed at all.

    @constant kVSFailNeedsUpdate
                    The request failed because the helper tool is installed but out of date. 
                    VSDiagnoseFailure will never return this value.  However, if you detect that 
                    the helper tool is out of date (typically by sending it a "get version" request) 
                    you can pass this value to VSFixFailure to force it to update the tool.
*/

enum {
	kVSFailUnknown,
	kVSFailDisabled,
	kVSFailPartiallyInstalled,
	kVSFailNotInstalled,
	kVSFailNeedsUpdate
};
typedef uint32_t VSFailCode;

/*!
    @function       VSDiagnoseFailure

    @abstract       Determines the cause of a failed request.
    
    @discussion     If VSExecuteRequestInHelperTool fails with an error (indicating an 
					IPC failure), you can call this routine to determine what went wrong.  
					It returns a VSFailCode value indicating the cause of the failure.  
					You should use this value to tell the user what's going on and what 
					you intend to do about it.  Once you get the user's consent, you can 
                    call VSFixFailure to fix the problem.
                    
                    For example, if this function result is kVSFailDisabled, you could put up the 
                    dialog saying:
                    
                        My privileged helper tool is disabled.  Would you like to enable it?
                        This operation may require you to authorize as an admin user.
                        [Cancel] [[Enable]]

                    On the other hand, if this function result is kVSFailNotInstalled, the dialog might be:
                    
                        My privileged helper tool is not installed.  Would you like to install it?
                        This operation may require you to authorize as an admin user.
                        [Cancel] [[Install]]
                    
                    VSDiagnoseFailure will never return kVSFailNeedsUpdate.  It's your responsibility 
                    to detect version conflicts (a good way to do this is by sending a "get version" request 
                    to the helper tool).  However, once you've detected a version conflict, you can pass 
                    kVSFailNeedsUpdate to VSFixFailure to get it to install the latest version of your 
                    helper tool.

                    If you call this routine when everything is working properly, you're likely to get 
                    a result of kVSFailUnknown.

    @param auth     A reference to your program's authorization instance; you typically get this 
                    by calling AuthorizationCreate.
    
                    This must not be NULL.

    @param bundleID The bundle identifier for your program.

                    This must not be NULL.
    
    @result         A VSFailCode value indicating the cause of the failure.  This will never be 
                    kVSFailNeedsUpdate.
*/

extern VSFailCode VSDiagnoseFailure(
	AuthorizationRef			auth,
	CFStringRef					bundleID
);

/*!
    @function       VSFixFailure

    @abstract       Installs, or reinstalls, the privileged helper tool.
    
    @discussion     This routine installs or reinstalls the privileged helper tool.  Typically 
                    you call this in response to an IPC failure talking to the tool.  You first 
                    diagnose the failure using VSDiagnoseFailure and then call this routine to 
					fix the failure by installing (or reinstalling) the tool.
                    
                    Because the helper tool is privileged, installing it is a privileged 
                    operation.  This routine will do its work by calling 
                    AuthorizationExecuteWithPrivileges, which is likely to prompt the user 
                    for an admin name and password.

    @param auth     A reference to your program's authorization instance; you typically get this 
                    by calling AuthorizationCreate.
    
                    This must not be NULL.

    @param bundleID The bundle identifier for your program.

                    This must not be NULL.

    @param installToolName
                    The name of the install tool within your bundle.  You should place the tool 
                    in the executable directory within the bundle.  Specifically, the tool must be 
                    available by passing this name to CFBundleCopyAuxiliaryExecutableURL.

                    This must not be NULL.

    @param helperToolName
                    The name of the helper tool within your bundle.  You should place the tool 
                    in the executable directory within the bundle.  Specifically, the tool must be 
                    available by passing this name to CFBundleCopyAuxiliaryExecutableURL.

                    This must not be NULL.

    @param failCode A value indicating the type of failure that's occurred.  In most cases you get this 
                    value by calling VSDiagnoseFailure.
	
	@result			An OSStatus code (see VSErrnoToOSStatus and VSOSStatusToErrno).			
*/

extern OSStatus VSFixFailure(
	AuthorizationRef			auth,
	CFStringRef					bundleID,
	CFStringRef					installToolName,
	CFStringRef					helperToolName,
	VSFailCode					failCode
);

/////////////////////////////////////////////////////////////////
#pragma mark ***** Utility Routines

/*!
    @functiongroup  Utilities
*/

/*!
    @function       VSErrnoToOSStatus

    @abstract       Convert an errno value to an OSStatus value.
    
    @discussion     All errno values have accepted alternatives in the errSecErrnoBase 
					OSStatus range, and this routine does the conversion. For example, 
					ENOENT becomes errSecErrnoBase + ENOENT. Any value that's not 
					recognised just gets passed through unmodified.
                    
                    A value of 0 becomes noErr.

					For more information about errSecErrnoBase, see DTS Q&A 1499 
					<http://developer.apple.com/qa/qa2006/qa1499.html>.
					
    @param errNum   The errno value to convert.
	
	@result			An OSStatus code representing the errno equivalent.
*/

extern OSStatus VSErrnoToOSStatus(int errNum);

/*!
    @function       VSOSStatusToErrno

    @abstract       Convert an OSStatus value to an errno value.
    
    @discussion     This function converts some specific OSStatus values (Open Transport and
					errSecErrnoBase ranges) to their corresponding errno values.  It more-or-less 
					undoes the conversion done by VSErrnoToOSStatus, including a pass 
					through for unrecognised values.
                    
                    It's worth noting that there are many more defined OSStatus error codes 
                    than errno error codes, so you're more likely to encounter a passed 
                    through value when going in this direction.

                    A value of noErr becomes 0.

					For more information about errSecErrnoBase, see DTS Q&A 1499 
					<http://developer.apple.com/qa/qa2006/qa1499.html>.

    @param errNum   The OSStatus value to convert.
	
	@result			An integer code representing the OSStatus equivalent.
*/

extern int      VSOSStatusToErrno(OSStatus errNum);

/*!
    @function       VSGetErrorFromResponse

    @abstract       Extracts the error status from a helper tool response.

    @discussion     This function extracts the error status from a helper tool response. 
                    Specifically, its uses the kVSErrorKey key to get a CFNumber and 
                    it gets the resulting value from that number.

    @param response A helper tool response, typically acquired by calling VSExecuteRequestInHelperTool.
    
                    This must not be NULL
	
	@result			An OSStatus code (see VSErrnoToOSStatus and VSOSStatusToErrno).
*/

extern OSStatus VSGetErrorFromResponse(CFDictionaryRef response);

/*!
    @function       VSCloseDescriptorArray

    @abstract       Closes all of the file descriptors referenced by a CFArray.

    @discussion     Given a CFArray of CFNumbers, treat each number as a file descriptor 
                    and close it.

                    The most common reason to use this routine is that you've executed, 
                    using VSExecuteRequestInHelperTool, a request that returns a response 
                    with embedded file descriptors, and you want to close those descriptors. 
                    In that case, you typically call this as:

                    VSCloseDescriptorArray( CFDictionaryGetValue(response, CFSTR(kVSDescriptorArrayKey)) );

    @param descArray
                    The array containing the descriptors to close.
    
                    This may be NULL, in which case the routine does nothing.
*/

extern void VSCloseDescriptorArray(
	CFArrayRef					descArray
);

/////////////////////////////////////////////////////////////////
#pragma mark ***** Utility Routines

// The following definitions are exported purely for the convenience of the 
// install tool ("VSAuthorizationHelperToolInstaller.c").  You must not 
// use them in your own code.

#if !defined(VS_PRIVATE)
    #define VS_PRIVATE 0
#endif
#if VS_PRIVATE

	// Hard-wired file system paths for the launchd property list file and 
	// the privileged helper tool.  In all cases, %s is a placeholder 
	// for the bundle ID (in file system representation).
	
    #define kVSPlistPathFormat             "/Library/LaunchDaemons/%s.plist"

    #define kVSToolDirPath                 "/Library/PrivilegedHelperTools"			// KEEP IN SYNC!
    #define kVSToolPathFormat              "/Library/PrivilegedHelperTools/%s"			// KEEP IN SYNC!
	
	// Commands strings for the install tool.

    #define kVSInstallToolInstallCommand "install"
    #define kVSInstallToolEnableCommand  "enable"

	// Magic values used to bracket the process ID returned by the install tool.
	
    #define kVSAntiZombiePIDToken1 "cricket<"
    #define kVSAntiZombiePIDToken2 ">bat"
    
    // Magic value used to indicate success or failure from the install tool.
    
    #define kVSInstallToolSuccess "oK"
    #define kVSInstallToolFailure "FailUrE %d"

#endif

#ifdef __cplusplus
}
#endif

#endif
