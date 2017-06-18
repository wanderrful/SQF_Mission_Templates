#
#  This script will copy the boilerplate files from my master folder
#  to each of the appropriate mission folders.  Use this before packaging!
#
#  Use this to refresh all mission folders' important files after implementing changes!
#
#
#
#



IFS='+' #because of the spaces in the folder pathnames, i need to change this!



MissionFolder='/cygdrive/d/docs/arma 3 - Other Profiles/sixtyfour/missions/'
MasterFolder='/cygdrive/d/docs/arma\ 3\ -\ Other\ Profiles/sixtyfour/_library/templates'



for template in $MasterFolder/*
do
	if [ -d $template ]
	then
	    for folder in $MissionFolder/*
	    do
		TemplateName=${template##/*/}
		
		prefix=${folder##/*/}
		
		MissionType={$prefix%%_*}
		
		
		if [ $TemplateName == ${prefix%%_*} ]
		then
		    echo 'Distributing the master files for the ' $TemplateName ' template...'
	    	    cp -r $template/* $folder/
		fi
	    done
	fi
done



echo 'Done!'
