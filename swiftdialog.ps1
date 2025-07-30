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
	centericon
	centreicon
}

#SF icon weight
enum SFIconWeight {
	thin
	light
	regular
	medium
	heavy
	bold
}

#SF icon animation type
enum SFAnimationType {
	variable
	variablereverse
	variableiterative
	variableiterativereversing
	variablecumulative
	pulse
	pulsebylayer
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

function isValidFontName {
	param (
		[Parameter(Mandatory = $true)] [string] $theFontName
	)

	#this returns an array of strings of all the fonts on the system
	$theInstalledFonts = Invoke-Expression -Command "/Applications/Dialog.app/Contents/MacOS/Dialog --listfonts"

	#because this adds whitespace to the front of each string, we shove this into an arraylist so we can get rid of that easier
	[System.Collections.ArrayList]$theTrimmedFonts = @()

	#iterate through and build our array list, using out-null to suppress the index listing in the window
	foreach($font in $theFonts) { 
		$theTrimmedFont = $font.Trim()  
		$theTrimmedFonts.Add($theTrimmedFont) | Out-Null
	}

	#now test for the existence of the passed font name
	$fontExists = $theTrimmedFonts -contains $theFontName

	#return result
	return $fontExists
}

function helpMessage {
	param (
		[Parameter(Mandatory = $true)][string] $SDHelpMessage
	)

	return "$theReturn --helpMessage $SDHelpMessage"
}

function icon {
	param (
		#since the first four parameters for icons are mutually exclusive, we use parameter sets.
		#you have to have ONE of the five, but only one of the five
		[Parameter(Mandatory = $true, ParameterSetName = 'iconPath')] [string] $SDIconPath,
		[Parameter(Mandatory = $true, ParameterSetName = 'iconURL')] [string] $SDIconURL,
		[Parameter(Mandatory = $true, ParameterSetName = 'iconType')] [iconType] $SDIconName,
		[Parameter(Mandatory = $true, ParameterSetName = 'iconText')] [string] $SDIconText,
		[Parameter(Mandatory = $true, ParameterSetName = 'iconSF')] [string] $SDSFIconName,
		[Parameter(Mandatory = $false)] [double] $SDIconAlpha,
		[Parameter(Mandatory = $false)] [string] $SDIconDark,
		[Parameter(Mandatory = $false)] [double] $SDIconSize,
		[Parameter(Mandatory = $false)] [iconPosition] $SDIconPosition,
		[Parameter(Mandatory = $false)] [string] $SDIconOverlay,
		[Parameter(Mandatory = $false)] [string] $SDIconOverlayBGColor,
		[Parameter(Mandatory = $false)] [SFIconWeight] $SDSFIconWeight,
		[Parameter(Mandatory = $false)] [SFAnimationType] $SDSFAnimationType,
		[Parameter(Mandatory = $false)] [string] $SDSFIconColor,
		[Parameter(Mandatory = $false)] [string] $SDSFIconColor2,
		[Parameter(Mandatory = $false)] [string] $SDSFIconPalette
	)

	#function globals
	$theSFAnimationType = ""

	#This is where we handle the 5 "main" icon options, i.e. the mutually exclusive ones
	#since one of these has to exist for the function to run at all, this allows us to
	#make that assumption. 
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
		#thought about doing URL Format validation, then realized that would be more
		#work than it's worth. So what you pass is what you get.
		$theReturn = "$theReturn  --icon `"$SDIconURL`" "
	} elseif ($SDIconName) {
		$theReturn = "$theReturn  --icon $SDIconName "
	} elseif ($SDIconText) {
		$theReturn = "$theReturn --icon text=`"$SDIconText`" "
	} else {
		#SF handling here
		#building this out as we hit the different options
		#basic option.
		#also, no use of quotes here, doesn't work if you do. Sigh.
		#we'll add the trailing space at the end
		$theReturn = "$theReturn --icon SF=$SDSFIconName"

		#the basics are done, now the options, yey
		if ($SDSFIconColor) {
			$theReturn = "$theReturn,color=$SDSFIconColor"
		} 
		
		if ($SDSFIconColor2) {
			$theReturn = "$theReturn,color2=$SDSFIconColor2"
		} 
		
		if ($SDSFIconWeight) {
			$theReturn = "$theReturn,weight=$SDSFIconWeight"
		} 
		
		if ($SDSFIconPalette) {
			$theReturn = "$theReturn,palette=$SDSFIconPalette"
		} 
		
		if ($SDSFAnimationType) {
			#this gets tedious because of limitations in PS enums
			#so we implement this as a switch because unlike the SF options
			#if we get here we KNOW there's an option and there's only one
			switch ($SDSFAnimationType) {
				"variable" { $theSFAnimationType = $SDSFAnimationType }
				"variablereverse" {$theSFAnimationType = "variable.reversing"}
				"variableiterative" {$theSFAnimationType = "variable.iterative"}
				"variableiterativereversing" {$theSFAnimationType = "variable.iterative.reversing"}
				"variablecumulative" {$theSFAnimationType = "variable.cumulative"}
				"pulse" {$theSFAnimationType = "pulse"}
				"pulsebylayer" {$theSFAnimationType = "pulse.bylayer"}
				Default {""}
			}
			$theReturn = "$theReturn,animation=$theSFAnimationType"
		}
		#insert the trailing space for other params
		$theReturn = "$theReturn "
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
			#put the icon alpha in the return
			$theReturn = "$theReturn --iconalpha $SDIconAlpha "
		} else {
			return "Invalid icon alpha variable, it must be a decimal number between 0.0 and 1.0"
		}
	}

	if($SDIconSize) {
		$theReturn = "$theReturn --iconsize $SDIconSize "
	}

	if($SDIconPosition) {
		$theReturn = "$theReturn --$SDIconPosition "
	}

	if($SDIconOverlay) {
		$theReturn = "$theReturn --overlayicon `"$SDIconOverlay`" "

		if($SDIconOverlayBGColor) {
			$theReturn = "$theReturn,bgcolor=$SDIconOverlayBGColor "
		}
		
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
		[Parameter(Mandatory = $true)][string] $SDTitle,
		#font color has to be hex, so #00A4C7 We are absolutely not checking this
		[Parameter(Mandatory = $false)] [string] $SDTitleFontColor,
		[Parameter(Mandatory = $false)] [double] $SDTitleFontSize,
		[Parameter(Mandatory = $false)] [SFIconWeight] $SDTitleFontWeight,
		#build a function using --listfonts to validate font name choices. Assigning that to a var creates
		#an array that we can check for presence of name in
		[Parameter(Mandatory = $false)] [string] $SDTitleFontName
	)
	$titleFontParams = ""
	
	#the title text has to be quoted
	$theReturn = "$theReturn --title `"$SDTitle`" "
	#deal with expanding the quoted string in the string, it has to have quotes. 
	
	#title font color
	if(($SDTitleFontColor) -and ([string]::IsNullOrEmpty($titleFontParams))) {
		#this is the first param
		$titleFontParams = "color=$SDTitleFontColor"
	} elseif (($SDTitleFontColor) -and (-not [string]::IsNullOrEmpty($titleFontParams))) {
		#there's already a param
		$titleFontParams = "$titleFontParams,color=$SDTitleFontColor"
	}

	#title font weight
	if(($SDTitleFontWeight) -and ([string]::IsNullOrEmpty($titleFontParams))) {
		#this is the first param
		$titleFontParams = "weight=$SDTitleFontWeight"
	} elseif (($SDTitleFontWeight) -and (-not [string]::IsNullOrEmpty($titleFontParams))) {
		#there's already a param
		$titleFontParams = "$titleFontParams,weight=$SDTitleFontWeight"
	}

	#title font size
	if(($SDTitleFontSize) -and ([string]::IsNullOrEmpty($titleFontParams))) {
		#this is the first param
		$titleFontParams = "size=$SDTitleFontSize"
	} elseif (($SDTitleFontSize) -and (-not [string]::IsNullOrEmpty($titleFontParams))) {
		#there's already a param
		$titleFontParams = "$titleFontParams,size=$SDTitleFontSize"
	}

	#title font name, this will be fun
	if(($SDTitleFontName) -and ([string]::IsNullOrEmpty($titleFontParams))) {
		#this is the first param
		#verify this is a valid font name
		$isValidFont = isValidFontName -theFontName $SDTitleFontName
		if($isValidFont) {
			$titleFontParams = "name=$SDTitleFontName"
		} else {
			return "Font $SDTitleFontName does not exist on this system"
		}	
	} elseif (($SDTitleFontName) -and (-not [string]::IsNullOrEmpty($titleFontParams))) {

		#verify this is a valid font name
		$isValidFont = isValidFontName -theFontName $SDTitleFontName
		if($isValidFont) {
			$titleFontParams = "$titleFontParams,name=$SDTitleFontName"
		} else {
			return "Font $SDTitleFontName does not exist on this system"
		}	
	}

	#check again for actual font params so we can properly quote them
	if(-not [string]::IsNullOrEmpty($titleFontParams)) {
		$titleFontParams = "`"$titleFontParams`""
		
		# add the title font params to $theReturn
		$theReturn = "$theReturn --titlefont $titleFontParams "
	}

	return $theReturn
}



#$theIconPath = icon -SDSFIconName "rainbow" -SDSFIconColor "auto" -SDSFIconWeight "heavy" -SDSFAnimationType "variableiterativereversing"
#$theIconPath

$theTitleTest = title -SDTitle "test" -SDTitleFontWeight regular 
$theTitleTest

#Invoke-Expression "$swiftDialogPath --title blah

