#!/bin/sh

displayMenu(){
	echo
	echo "POSSIBLE OPTIONS"
	echo "----------------"
	echo "1-Search address book"
	echo "2-Add an entry"
	echo "3-Remove an entry"
	echo "4-Edit an entry"
	echo "5-Exit"
}

getConfirmation(){
	echo -n "Do you confirm the operation?(y|n)"
	read answer
	while [ $answer != "y" ] && [ $answer != "n" ]
	do
		echo
		echo "Please enter either y for yes or n for no."
		echo -n "Do you confirm the operation?(y|n)"
		read answer
	done
	case $answer in
		y)	result=0
			;;
		n)	result=1
			;;
	esac
	return $result
}

checkDataFile(){
	datafile=./addressbook
	if [ ! -f "$datafile" ]; then
		echo "Data file does not exist but it will be created!"
		touch addressbook
	fi
}

isInteger(){
	#Integer is expected to start between 1-9.
	echoresult=`echo "$1" | grep -E "^[1-9][0-9]*$"`
	if [ -z "$echoresult" ]; then
		#There is not any match so it is not integer.
		result=1
	else
		#It is integer.
		result=0
	fi
	return $result
}

editSearchedEntry(){
	#$1 is total number of matched entries from searchDataFile function.
	#$2 is keyword given by user from searchDataFile function.
	echo
	echo -n "Would you like to edit any entry(y|n)?"
	read answer
	if [ "$answer" = "y" ]; then
		echo -n "Please enter entry number you would like to edit:"
		read number
		isInteger $number
		isIntegerresult=$?
		while [ "$isIntegerresult" -eq "1" ] || [ "$number" -gt "$1" ] 
		do
			echo -n "Please select number only from shown results:"
			read number
			isInteger $number
			isIntegerresult=$?
		done
		name=`grep -i "$2" addressbook | nl | grep "$number" | awk -F: '{ print $1 }' | awk '{ print $2 }'`
		surname=`grep -i "$2" addressbook | nl | grep "$number" | awk -F: '{ print $1 }' | awk '{ print $3 }'`
		email=`grep -i "$2" addressbook | nl | grep "$number" | awk -F: '{ print $2 }'`
		phonenumber=`grep -i "$2" addressbook | nl | grep "$number" | awk -F: '{ print $3 }'`
		echo
		echo "Name [ $name ]"
	        echo "Surname [ $surname ]"
		echo "Phone [ $email ]"
		echo "Email [ $phonenumber ]"
		editEntry $name $surname $email $phonenumber
	fi
}

searchDataFile(){
	checkDataFile
	echo
	echo "Enter a keyword to look up an entry in the data file. For example Name or Surname or Email or Phone."
	echo -n "Please enter your keyword:"
	read keyword
	while [ -z "$keyword" ]
	do
		echo "Input can not be empty!"
		echo -n "Please enter your keyword:"
		read keyword
	done
	grep -iqs "$keyword" addressbook
	grepreturncode=$?
	if [ "$grepreturncode" -eq "0" ]; then
		grepoutput=`grep -i "$keyword" addressbook | nl`
		numberofmatchedlines=`grep -ic "$keyword" addressbook`
		echo
		echo "Total number of entries with given keyword is: $numberofmatchedlines"
		echo
		echo "$grepoutput"
		editSearchedEntry $numberofmatchedlines $keyword
	else
		echo "There is not any entry with keyword $keyword"
	fi
}

editEntry(){
#This function is invoked in two cases:
#1-When user tries to add an entry that is already existed. Then the user is prompted if user would like to
#edit the existing record.
#2-When option 4 is chosen from POSSIBLE OPTIONS which is "Edit an entry". Then user is prompted to search
#an entry that is wanted to be edited. Once any matching entry found user is prompted if user would like to
#to edit any matching entry.
	echo
	echo -n "Enter a new Name:"
	read editedname
	echo -n "Enter a new Surname:"
	read editedsurname
	echo -n "Enter Email:"
	read editedemail
	echo -n "Enter Phone:"
	read editedphone
	echo
 	echo "New edited entry is $editedname $editedsurname $editedemail $editedphone"
	getConfirmation
	getConfirmationreturncode=$?
	if [ "$getConfirmationreturncode" -eq "0" ]; then
		sed -i "s/$1 $2:$3:$4/$editedname $editedsurname:$editedemail:$editedphone/I" addressbook
		echo "Edit operation is successfull."
	fi	
}

addEntry(){
	checkDataFile
	echo
	echo -n "Enter Name:"
	read name
	echo -n "Enter Surname:"
	read surname
	echo -n "Enter Email:"
	read email
	echo -n "Enter Phone:"
	read phone
	while [ -z "$name" ] || [ -z "$surname"] || [ -z "$email" ] || [ -z "$phone" ]
	do
		echo
		echo "The required fields can not be empty!"
		echo
		echo -n "Enter Name:"
		read name
		echo -n "Enter Surname:"
		read surname
		echo -n "Enter Email:"
		read email
		echo -n "Enter Phone:"
		read phone
	done
	echo
 	echo "New entry is $name $surname $email $phone"
	getConfirmation
	getConfirmationreturncode=$?
	if [ "$getConfirmationreturncode" -eq "0" ]; then
		checkEntry $name $surname $email $phone
		checkentryreturncode=$?
		echo
		if [ "$checkentryreturncode" -eq "0" ]; then
			echo -n "The entry is already existed. Would you like to edit it?(y|n)"
			read answer
			if [ "$answer" = "y" ]; then
				editEntry $name $surname $email $phone
			fi

		else
			echo "$name $surname:$email:$phone" >> addressbook
			echo "The new entry is added successfully."
		fi
	fi
}

checkEntry(){
#Checks whether an entry is already existed.
grep -iqs "$1 $2:$3:$4" addressbook
grepreturncode=$?
if [ "$grepreturncode" -eq "0" ]; then
	#Entry exists already.
	result=0
else
	#Entry either does not exist(1) or grep outputs error message(2).
	result=1
fi

return $result
}

checkEntrybyPhone(){
	grep -qs "$1" addressbook
	grepreturncode=$?
if [ "$grepreturncode" -eq "0" ]; then
	result=0
else
	result=1
fi

return $result
}

checkEntrybyEmail(){
	grep -qs "$1" addressbook
	grepreturncode=$?
if [ "$grepreturncode" -eq "0" ]; then
	result=0
else
	result=1
fi

return $result
}

removeEntry(){
	checkDataFile
	echo
	echo "Remove by search criteria from one of the followings:"
	echo "1-Phone"
	echo "2-Email"
	echo "3-Cancel"
	echo -n "Your choice:(Just number)"
	read choice
	while [ "$choice" != "1" ] && [ "$choice" != "2" ] && [ "$choice" != "3" ]
	do
		echo "Please only enter one number from the shown ones as an input!"
		echo "1-Phone"
		echo "2-Email"
		echo "3-Cancel"
		echo -n "Your choice:(Just number)"
		read choice

	done
	case $choice in
		1)	echo
			echo -n "Enter phone number using +(country code) format:"
			read phonenumber
			while [ -z "$phonenumber" ]
			do
				echo "Input can not be empty!"
				echo -n "Enter phone number using +(country code) format:"
				read phonenumber
			done
			checkEntrybyPhone $phonenumber
			checkentrybyphonereturncode=$?
			if [ "$checkentrybyphonereturncode" -eq "0" ]; then
				grepoutput=`grep "$phonenumber" addressbook`
				echo
				echo "The entry that will be removed is: $grepoutput"
				getConfirmation
				getConfirmationreturncode=$?
				if [ "$getConfirmationreturncode" -eq "0" ]; then
					sed -i "/$phonenumber/d" addressbook
					echo "The entry $grepoutput is removed successfully."
				fi
			else
				echo "The entry that is being wanted to be removed is not found!"
			fi
			;;
		2)	echo
			echo -n "Enter email address:"
			read email
			while [ -z "$email" ]
			do
				echo "Input can not be empty!"
				echo -n "Enter email address:"
				read email
			done
			checkEntrybyEmail $email
			checkentrybyemailreturncode=$?
			if [ "$checkentrybyemailreturncode" -eq "0" ]; then
				grepoutput=`grep "$email" addressbook`
				echo
				echo "The entry that will be removed is: $grepoutput"
				getConfirmation
				getConfirmationreturncode=$?
				if [ "$getConfirmationreturncode" -eq "0" ]; then
					sed -i "/$email/d" addressbook
					echo "The entry $grepoutput is removed successfully."
				fi
			else
				echo "The entry that is being wanted to be removed is not found!"
			fi
			;;
	esac

}

#MAIN SECTION
choice="0" #Initialization
while [ "$choice" != "5" ]
do
	displayMenu
	echo
	echo -n "Your choice:"
	read choice
	while [ "$choice" != "1" ] && [ "$choice" != "2" ] && [ "$choice" != "3" ] && [ "$choice" != "4" ] && [ "$choice" != "5" ]
	do
		echo "Please only enter one possible option as an input!"
		displayMenu
		echo -n "Your choice:(Just number)"
		read choice
	done
	case $choice in
		1)	searchDataFile
			;;
		2)	addEntry
			;;
		3)	removeEntry
			;;
		4)	echo
			echo "First seach an entry that you would like to edit."
			searchDataFile
			;;
	esac
done
exit 0
