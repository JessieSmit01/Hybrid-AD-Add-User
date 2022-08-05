Connect-AzureAD
#User to copy groups from.
$AzureUserCopyFrom
#User to copy groups to.
$AzureUserCopyTo

#Prompt for email of the account which groups will be copied from. Check to ensure the account exists. If account does not exist, prompt again.
Do {
    try{
        $UserCopy = Read-Host "Enter a user's email to copy from: "
        $AzureUserCopyFrom = Get-AzureADUser -ObjectId $UserCopy
        break
        }
    catch{Write-Host "User does not exist. Please try again."}

}While($true)

#Prompt for email of the account which groups will be copied to. Check to ensure the account exists. If account does not exist, prompt again.
Do {
    try{
        $UserCopyTo = Read-Host "Enter a user's email to copy to: "
        $AzureUserCopyTo = Get-AzureADUser -ObjectId $UserCopyTo
        break
        }
    catch{Write-Host "User does not exist. Please try again."}

}While($true)

#Grab all groups that belong to the user to be copied from.
$GroupsCopyFrom = Get-AzureADUserMembership -ObjectId $AzureUserCopyFrom.mail

#Grab all groups that belong to the user to be copied to.
$GroupsCopyTo = Get-AzureADUserMembership -ObjectId $AzureUserCopyTo.mail

#For each group to copy from, only add it to $GroupsToAdd if the group does not contain membership from $AzureUserCopyTo.
$GroupsToAdd = $GroupsCopyFrom | Where{$GroupsCopyTo -notcontains $_} | select-object ObjectId

#Loop through the list of filtered groups to add, add $AzureUserCopyTo to the group.
foreach ($i in $GroupsToAdd)
{
    Add-AzureADGroupMember -ObjectId $i.ObjectId -RefObjectId $AzureUserCopyTo.ObjectId
}



