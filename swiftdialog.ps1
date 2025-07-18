$swiftDialogPath = "/Applications/Dialog.app/Contents/MacOS/Dialog"
$theReturn = "$swiftDialogPath"

#We're using enums here because they help avoid the wrong params. PowerShell throws lovely errors
#when you don't use the right values for the enums
##enums

#icon type
enum iconType {
	info
	caution
	warning
	computer
}

#icon position
enum iconPosition {
	center
	centre
}

#message horizontal alignment
enum mhorizalign {
	left
	center
	centre
	right
}

#message vertical alignement/position
enum mvertalign {
	top
	centre
	center
	bottom
}

#window style
enum winStyle {
	presentation
	mini
	centered
	alert
	caution
	warning
}

function helpMessage {
	param (
		[Parameter(Mandatory = $true)][string] $SDHelpMessage
	)

	return "$theReturn --helpMessage $SDHelpMessage"
}

function icon {
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'iconPath')] [string] $SDIconPath,
		[Parameter(Mandatory = $true, ParameterSetName = 'iconURL')] [string] $SDIconURL,
		[Parameter(Mandatory = $true, ParameterSetName = 'iconType')] [iconType] $SDIconName,
		[Parameter(Mandatory = $true, ParameterSetName = 'iconText')] [string] $SDIconText,
		[Parameter(Mandatory = $false)] [double] $SDIconAlpha,
		[Parameter(Mandatory = $false)] [string] $SDIconDark,
		[Parameter(Mandatory = $false)] [double] $SDIconSize
	)

	if($SDIconPath) {
		#if they specificed a dark mode icon path and a "regular" path
		#We are only FW dark mode here.
		if($SDIconDark) {
			$theReturn = "$theReturn --icon `"$SDIconPath`":dark=`"$SDIconDark`" "
		} else {
			#we just add quote by default, makes life easier
			$theReturn = "$theReturn  --icon `"$SDIconPath`" "
		}
		
	} elseif ($SDIconURL) {
		#add URL validation code (format, not if what it points at is right)
		$theReturn = "$theReturn  --icon `"$SDIconURL`" "
	} elseif ($SDIconName) {
		$theReturn = "$theReturn  --icon $SDIconName "
	} else {
		$theReturn = "$theReturn --icon text=`"$SDIconText`" "
	}

	#yes, yes, extra code for the alpha, but we catch a lot of human error here.
	if($SDIconAlpha) {
		#okay, the param exists
		if(($SDIconAlpha -ge 0.0) -and ($SDIconAlpha -le 1.0)) {
			#the range is good
			#double-chack to make sure it's a double
			if($SDIconAlpha.GetType().Name -eq "Double") {
				#okay, it's a double in the right range, let's make sure it's only got one number after the decimal
				#convert double to a string
				$theNumberString = $SDIconAlpha.ToString()
				
				#does it actually have a dot, if not, we don't care, you can't force a 0 on the end
				if($theNumberString.Contains(".")) {
					#we only do this to check for excess decimals
					#split on the decimal char
					$theNumberStringArray = $theNumberString.Split(".")
					#assign out the array components
					$theInteger = $theNumberStringArray[0]
					#[-1] is shorthand for the last item in an array
					$theDecimal = $theNumberStringArray[-1]

					if($theDecimal.Length -gt 1) {
						#we only do this if there's more than one decimal number. if it's in range and
						#only one decimal, we don't need to do anything

						#Grab the first character of the decimal. We do this because the formatting
						#options for floats to get to one decimal are a rounding operation with no option to truncate
						#the -1 in powershell is shorthand for "last item", so we grab the first character of that
						#item
						$theDecimal = $theDecimal.Substring(0,1)
						#create a string version of the double
						$theDoubleString = "$theInteger.$theDecimal"
						#convert it to a double and assign back to $SDIconAlpha
						$SDIconAlpha = [Double]$theDoubleString
					}
				}
			} else {
				return "Invalid icon alpha variable, it must be a decimal number between 0.0 and 1.0"
			}
			#add the icon alpha to the return
			$theReturn = "$theReturn --iconalpha $SDIconAlpha "
		} else {
			return "Invalid icon alpha variable, it must be a decimal number between 0.0 and 1.0"
		}
	}

	if($SDIconSize) {
		$theReturn = "$theReturn --iconsize $SDIconSize "
	}

	return $theReturn
}

function mhalignment {
	#only works if --style not used. Another parameter set, 
	param (
		[Parameter(Mandatory = $true)] [mhorizalign] $SDMessageHAlignment
	)

	return "$theReturn --messagealignment $SDMessageHAlignment "
}

function mvalignment {
	#works with all styles but presentation
	#title follows this in styled windows as well, WHY. Makes me want to make this exclusive too
	param (
		[Parameter(Mandatory = $true)] [mvertalign] $SDMessageVAlignment
	)

	return "$theReturn --messageposition $SDMessageVAlignment "
}

function style {
	param (
		[Parameter(Mandatory = $true)] [winStyle] $SDDialogStyle
	)

	return "$theReturn --style $SDDialogStyle "
}

function subtitle {
	#only valid for system notification type, add check later
	#parameter set?
	param (
		[Parameter(Mandatory = $true)] [string] $SDSubTitle
	)

	return "$theReturn --subtitle $SDSubTitle "
}

function title {
	#not used for presentation style, add check later (maybe parameter set?)
	param (
		[Parameter(Mandatory = $true)][string] $SDTitle
	)

	return "$theReturn --title $SDTitle "
}



$theIconPath = icon -SDIconText "🙄" -SDIconAlpha 1.0
$theIconPath

#Invoke-Expression "$swiftDialogPath --title blah

