
function InGroup {
    ##########################################################################
    ##  Group check - Returns True/False for whether the user is in a group
    ##########################################################################
    <#
      .SYNOPSIS
          Check if the current user is in a specified group
      .DESCRIPTION
          Check if the current user is in a specified group
      .PARAMETER GroupName
          The name of the group to check
      .EXAMPLE
          # Check if the current user is in the Administrators group
          $b = InGroup 'Administrators'
  #>
    Param(
        [string]$GroupName
    )

    if ($GroupName) {
        $mytoken = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $me = New-Object System.Security.Principal.WindowsPrincipal($mytoken)
        return $me.IsInRole($GroupName)
    }
    else {
        $user_token = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $groups = New-Object System.Collections.ArrayList
        foreach ($group in $user_token.Groups) {
            [void] $groups.Add( $group.Translate("System.Security.Principal.NTAccount") )
        }
        return $groups
    }
}

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



Export-ModuleMember -Function InGroup
