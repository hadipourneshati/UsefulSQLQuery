<#
Description:
    This module used for bulk copy table from a remote(or local) sql server to remote(or local) sql server.
Author:
    Hadi Pourneshati 
Usage:
    copy the module file(BulkCopy.ps1) somewhere on your computer.
    on the powershell type: Import-Module "the\path\you\coppied\module"
        for example: Import-Module "C:\PowershellModules\BulkCopy.ps1"
    after importing module you can use it
        --notice that the destination table must be exists
        for example:
            copy data from local table to remote database:
                BulkCopy -SourceConnectionString "Server=localhost;Database=MySourceDB;Integrated Security=True;" -SourceQuery "SELECT * FROM dbo.[MySourceTable] with(nolock)" -DestinationConnectionString "Server=MyDestinationServerNameOrIp;Database=MyDestinationDB;User Id=MyDestinationUser;Password=P@ssw0rd;" -DestinationTable "dbo.[MyDestinationTable]" -UnwantedColumns @("VersionNumber")
#>
Function BulkCopy{
    param(
        [string]$SourceConnectionString=$null,
        [string]$SourceQuery=$null,
        [string]$DestinationConnectionString=$null,
        [string]$DestinationTable=$null,
        [int]$BatchSize=10000,
        [array]$UnwantedColumns=@()
    )
    if(
        (-not $SourceConnectionString) -or (-not $SourceQuery) -or (-not $DestinationConnectionString) -or (-not $DestinationTable)
    ){
        Write-Error -Message "Please enter mandatory params(SourceConnectionString, SourceQuery, DestinationConnectionString, DestinationTable)!!!" -ErrorAction Stop
    }

    ### Source
    try{
        $SourceConnection=New-Object System.Data.SqlClient.SqlConnection
        $SourceConnection.ConnectionString=$SourceConnectionString
        $SourceConnection.Open()

    }
    catch{
        Write-Error -Message "Can not connect to source database!!! because: $PSItem" -ErrorAction Stop
    }

    ### Destination
    try{
        $DestinationConnection=New-Object System.Data.SqlClient.SqlConnection
        $DestinationConnection.ConnectionString=$DestinationConnectionString
        $DestinationConnection.Open()
    }
    catch{
        if ($SourceConnection.State -eq [System.Data.ConnectionState]::Open){$SourceConnection.Close()}
        Write-Error -Message "Can not connect to destination database!!! because: $PSItem" -ErrorAction Stop
    }

    ### Read source
    try{
        $SourceCommand=$SourceConnection.CreateCommand()
        $SourceCommand.CommandText=$SourceQuery
        $DataTable=new-object System.Data.DataTable
        $DataAdapter=New-Object System.Data.SqlClient.SqlDataAdapter($SourceCommand)
        [void]$DataAdapter.Fill($DataTable)
    }
    catch{
        if ($DestinationConnection.State -eq [System.Data.ConnectionState]::Open){$DestinationConnection.Close()}
        Write-Error -Message "Can not read data from source database!!! because: $PSItem" -ErrorAction Stop
    }
    finally{
        if ($SourceConnection.State -eq [System.Data.ConnectionState]::Open){$SourceConnection.Close()}
    }

    ### Bulk insert to destination
    try{
        $BulkCopy=New-Object System.Data.SqlClient.SqlBulkCopy $DestinationConnection
        $BulkCopy.DestinationTableName=$DestinationTable
        $BulkCopy.BatchSize=$BatchSize
        $BulkCopy.BulkCopyTimeout=0
        foreach ($Column in $DataTable.Columns.ColumnName){
            if ($UnwantedColumns -notcontains $Column){
                [void]$BulkCopy.ColumnMappings.Add($Column, $Column)
            }
        }
        $BulkCopy.WriteToServer($DataTable)
    }
    catch{
        Write-Error -Message "Can not copy data to destination database!!! because: $PSItem" -ErrorAction Stop
    }
    finally{
        if ($SourceConnection.State -eq [System.Data.ConnectionState]::Open){$SourceConnection.Close()}
        if ($DestinationConnection.State -eq [System.Data.ConnectionState]::Open){$DestinationConnection.Close()}
    }
}
