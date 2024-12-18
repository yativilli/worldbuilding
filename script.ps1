param($configPath)
Write-Host "Reading configuration from path $configPath";

try {

    $config = Get-Content -Path ($configPath) -Raw | Out-String | ConvertFrom-Json;
    $MIN_SEATS = $config.minSeats_nat;
    $data = Get-Content -Path ($config.pathToData) -Raw | Out-String |ConvertFrom-Json;
}
catch {
    Write-Host $_;
    exit;
}


$max_population = 0;
$seats_after_guaranteed = $config.maxSeats_nat;

# Add Min
foreach ($country in $data) {
    $country | Add-Member NoteProperty -Name "seats" -Value $MIN_SEATS; 
    $country | Add-Member NoteProperty -Name "percentage_population" -Value 0; 
    $country | Add-Member NoteProperty -Name "comma" -Value 0; 
    $country | Add-Member NoteProperty -Name "sta_seats" -Value ($config.minSeats_sta); 

    
    $max_population += $country.population;
    $seats_after_guaranteed -= $MIN_SEATS;
}
$data;

# Calculate Population Percentage
foreach ($c in $data) {
    $c.percentage_population = $c.population / $max_population;
}

# Allocate Seats with Hare/Niemeyer-Procedure
$count = $data.Count;
$divisor = $max_population / $seats_after_guaranteed;
$total_seats = 0;


foreach ($count in $data) {
    $seats = [math]::floor($count.population / $divisor);
    $count.seats += $seats;
    #    Write-Host "Seats $seats ";
}

# Calc comma seats
foreach ($c in $data) {
    $total_seats += $c.seats;
    $comma = ($c.population / $divisor) - $c.seats;
    $c.comma = $comma;
}

# Sort by the 'Comma' property
while ($total_seats -lt $config.maxSeats_nat) {
    # Sort by Least overrepresented
    Write-Host "After allocating: $total_seats/"$config.maxSeats_nat;
    Write-Host "Add Seat to "$data[0].name;
    $data = $data | Sort-Object -Property Comma -Descending

    # Add Seats and update comma
    $data[0].seats += 1;
    $total_seats += 1;
    $comma = ($data[0].population / $divisor) - $data[0].seats;
    $data[0].comma = $comma;
    
    #    Write-Host "Div: $div Seats: $"$c.seats" Comma:$comma";
}

Write-Host "After allocating: $total_seats/"$config.maxSeats_nat;
$data | ForEach-Object {
    Write-Output "Name: $($_.Name), Seats: $($_.Seats)"
}

$sum = 0;
$data | ForEach-Object{
    $sum += $_.sta_seats;
}

$data = $data | Sort-Object -Property seats -Descending
Write-Host "State-Council:$sum"   "Count: "$data.Count -ForegroundColor Green;
Set-Content -Path "C:\Code\worldbuilding\end.json" -Value ($data | ConvertTo-Json);