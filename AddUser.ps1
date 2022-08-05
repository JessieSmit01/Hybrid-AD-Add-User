
#Variable used to enter user creation loop more than one time
$AddUser = 'n'
 #Get Exchange admin credentials from user 
$ADCred = Get-Credential -Message "Please login to the exchange server"
$sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
$Session = New-PSSession -SessionOption $sessionOption -ConfigurationName Microsoft.Exchange -ConnectionUri http://ExchangeServerURI -Authentication Kerberos -Credential $ADCred
#start PowerShell session in the mail server

Import-PSSession $Session -DisableNameChecking

Do{
    #Prompt for first name, and last name
    $firstName = Read-Host -Prompt "Please enter the new user's first name"
    $lastName = Read-Host -Prompt "Please enter the new user's last name"
    $displayName = $firstName + " " + $lastName
    #prompt the user for a password
    $password = Read-Host -Prompt "Please enter a password for $($displayName)"


    #Default to first letter of first name with last name appended to the end. (John Smith -> jsmith)
    $domainName = ($firstName.Substring(0,1).ToLower() + $lastName.ToLower()) -replace '\s',''

    #check to see if a user exists with the first initial + last name.
    #if exists, revert to firstname.lastname naming scheme
    $UpnExists = Get-ADUser -Filter {sAMAccountName -eq $domainName}
    If ($UpnExists -eq $Null) {Write-Output "User added as $domainName"}
    Else {
    Set-Variable -Name "domainName" -Value ($firstName.ToLower() +"." + $lastName.ToLower())
    }

    #Check if username in the form of FirstName.LastName already exists. If so, prompt for a custom username
    Set-Variable -Name "UpnExists" -Value (Get-ADUser -Filter {sAMAccountName -eq $domainName})
    If ($UpnExists -eq $Null) {Write-Output "User added as $domainName"}
    Else {
    Set-Variable -Name "domainName" -Value (Read-Host -Prompt "Username in the forms: First initial + Last Name and FirstName.Lastname taken. Please enter a username: ")
    Write-Output "User added as $domainName"
    }

    #set email address variable for the new account
    $newEmail = $domainName + "@domain.ca"

    #declare variable to hold user with similar data that will be copied into new user account.
    $CopyFromUser = $Null
    #prompt user for an existing AD account to copy data from. If the account is does not exist, keep prompting.
    Do {
        try{Set-Variable -Name "CopyFromUser" -Value (Get-ADUser -Identity (Read-Host -Prompt "Please enter a User to copy details from") -Properties *)
            #check if user was found. If found, break out of loop
            if($CopyFromUser -ne $Null){break}
        }
        catch{"User does not exist. Please enter an existing user"}
    }While($True)

    #Write-Host (Get-ADUser -Filter {sAMAccountName -eq $CopyFromUser.SamAccountName})
    $CN = $CopyFromUser.CN
    #grab the DN from the copied user. Remove the CN
    $OU = ($CopyFromUser.DistinguishedName).Replace("CN=$($CN),","")


    #create the new mailbox/AD account
    New-RemoteMailbox -Name $displayName -FirstName $firstName -LastName $lastName -OnPremisesOrganizationalUnit $OU -UserPrincipalName $newEmail -Password (ConvertTo-SecureString $password -AsPlainText -Force)

    


    #Pause for 10 seconds. Allow AD to gather changes
    Write-Output "Please wait for AD to sync..."
    Start-Sleep -s 10


    #Get the new user that was just created
    $NewUser = Get-ADUser -Identity $domainName -Properties *

    #Copy groups from the reference user and add the new user into these groups
    $CopyFromUser.MemberOf | Where{$NewUser.MemberOf -notcontains $_} | Add-ADGroupMember -Members $NewUser


    #Set all other required AD properties
    #General Properties
    $NewUser.description = $CopyFromUser.description
    Write-Output "Description Updated"
    $NewUser.office = $CopyFromUser.office
    Write-Output "Office Updated"

    #Address Properties
    $NewUser.StreetAddress = $CopyFromUser.StreetAddress
    Write-Output "Street Address Updated"
    $NewUser.POBox = $CopyFromUser.POBox
    Write-Output "PO Box Updated"
    $NewUser.City = $CopyFromUser.City
    Write-Output "City Updated"
    $NewUser.PostalCode = $CopyFromUser.PostalCode
    Write-Output "Postal Code Updated"
    $NewUser.State = $CopyFromUser.State
    Write-Output "Province Updated"
    $NewUser.Country = $CopyFromUser.Country
    Write-Output "Country Updated"

    #Profile Properties
    $NewUser.ScriptPath = $CopyFromUser.ScriptPath
    Write-Output "Logon Script Updated"

    #Organization Properties
    $NewUser.Title = $CopyFromUser.Title
    Write-Output "Title Updated"
    $NewUser.Department = $CopyFromUser.Department
    Write-Output "Department Updated"
    $NewUser.Company = $CopyFromUser.Company
    Write-Output "Company Updated"
    $NewUser.Manager = $CopyFromUser.Manager
    Write-Output "Manager Updated"

    #Telephone Properties
    $NewUser.Fax = $CopyFromUser.Fax
    Write-Output "Fax Updated"
    
    #Set AD user using local saved instance
    Set-ADUser -Instance $NewUser

    #Ask user if they would like to create a new account
    Set-Variable -Name "AddUser" -Value (Read-Host "Would you like to create another account? [y/n]")
    #If user does not enter y or n keep prompting
    while($AddUser -ne 'y' -and $AddUser -ne 'n')
    {
        Set-Variable -Name "AddUser" -Value (Read-Host "Input Invalid. Would you like to create another account? [y/n]")
        
        
    }

    
}
While($AddUser -eq 'y')

#remove session with mail server
Remove-PSSession $Session


Write-Output "Users have been added. Exiting Script."
