#Указать путь к списку виртуальных машин\компьютеров
$servers = Get-Content -Path "C:\ServersTest.txt" -ErrorAction Inquire
# Указать путь к месту хранения логов, обычно хранятся тут
$path = "C:\ProgramData\Microsoft\Diagnosis\ETLLogs"

$results = @()

function GetETLInfo {
    param (
        $server,
        $path
    )

    $result = Invoke-Command -ComputerName $server -ScriptBlock {
        param (
            $path,
            $server
        )
       $FolderSize = (Get-ChildItem -Path $path -Force -Recurse -ErrorAction SilentlyContinue -Filter "*.etl" | Measure-Object Length -ErrorAction SilentlyContinue -Sum).Sum / 1Gb
        return [PSCustomObject]@{
            Server = $server
            FolderSize = $FolderSize
        }
    }  -ArgumentList $path, $server  -AsJob

    return $result
} 

$jobsForCheckInfo = @()

foreach ($server in $servers) {
    $job = GetETLInfo -server $server -path $path
    $jobsForCheckInfo += $job
}

$results = $jobsForCheckInfo | Receive-Job -Wait -AutoRemoveJob -ErrorAction SilentlyContinue | Sort-Object FolderSize -Descending

$results | Format-Table -AutoSize -Force
